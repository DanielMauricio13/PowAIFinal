import ActivityKit
import Foundation

class LiveActivityManager {
    
    static let shared = LiveActivityManager()
    
    private var liveActivity: Activity<TimeTrackingAttributes>?
    private var dayPlanActivity: Activity<TimeTrackingAttributes>?
    
    private init() {}
    
    func startLiveActivity(set: Int) {
        let attriutes = TimeTrackingAttributes(Initial: Date())
        let state = TimeTrackingAttributes.ContentState(startTime: .now, set: set - 1)
        let contrent = ActivityContent(
            state: state,
            staleDate: nil,
            relevanceScore: LiveActivityRelevance.workout
        )
        
        liveActivity = try?  Activity<TimeTrackingAttributes>.request(attributes: attriutes, content: contrent, pushType: nil)
        prioritizeWorkoutOverDayPlan()
    }
    
    func endLiveActivity(set:Int)  {
        let finalContentState = TimeTrackingAttributes.ContentState(startTime: .now, set: 1 )
        let finalContent = ActivityContent(
            state: finalContentState,
            staleDate: nil,
            relevanceScore: LiveActivityRelevance.workout
        )
        
        Task {
            await liveActivity?.end(finalContent, dismissalPolicy: .immediate)
          
           // cancelNotification()
        }
    }

    func prioritizeWorkoutOverDayPlan() {
        let activities = Activity<TimeTrackingAttributes>.activities
        Task {
            for activity in activities {
                let state = activity.content.state
                let isDayPlan = state.dayPlanTitle != nil
                let content = ActivityContent(
                    state: state,
                    staleDate: isDayPlan ? dayPlanStaleDate(for: state) : nil,
                    relevanceScore: isDayPlan ? LiveActivityRelevance.dayPlan : LiveActivityRelevance.workout
                )
                await activity.update(content)
            }
        }
    }

    func updateDayPlan(blocks: [DayPlanBlock], date: Date, now: Date = Date()) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled,
              Calendar.current.isDate(date, inSameDayAs: now),
              let state = dayPlanState(blocks: blocks, date: date, now: now) else {
            endDayPlanActivity()
            return
        }

        let content = ActivityContent(
            state: state,
            staleDate: dayPlanStaleDate(for: state),
            relevanceScore: LiveActivityRelevance.dayPlan
        )

        if let activity = activeDayPlanActivity() {
            dayPlanActivity = activity
            Task { await activity.update(content) }
        } else {
            let attributes = TimeTrackingAttributes(Initial: now)
            dayPlanActivity = try? Activity<TimeTrackingAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        }
    }

    func endDayPlanActivity() {
        let activities = Activity<TimeTrackingAttributes>.activities.filter {
            $0.content.state.dayPlanTitle != nil
        }
        Task {
            for activity in activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        dayPlanActivity = nil
    }

    private func activeDayPlanActivity() -> Activity<TimeTrackingAttributes>? {
        if let dayPlanActivity {
            return dayPlanActivity
        }

        return Activity<TimeTrackingAttributes>.activities.first {
            $0.content.state.dayPlanTitle != nil
        }
    }

    private func dayPlanStaleDate(for state: TimeTrackingAttributes.ContentState) -> Date? {
        if state.dayPlanIsCurrentBlock == true {
            return state.dayPlanEndTime
        }
        return state.dayPlanLeaveTime ?? state.dayPlanEndTime
    }

    private func dayPlanState(
        blocks: [DayPlanBlock],
        date: Date,
        now: Date
    ) -> TimeTrackingAttributes.ContentState? {
        let calendar = Calendar.current
        let scheduledBlocks = blocks
            .filter { !$0.isDone && !$0.isAllDayCalendarCopy }
            .sorted { ($0.startHour, $0.startMinute) < ($1.startHour, $1.startMinute) }

        func blockStart(_ block: DayPlanBlock) -> Date? {
            calendar.date(
                bySettingHour: block.startHour,
                minute: block.startMinute,
                second: 0,
                of: date
            )
        }

        func blockEnd(_ block: DayPlanBlock) -> Date? {
            calendar.date(
                bySettingHour: block.endHour,
                minute: block.endMinute,
                second: 0,
                of: date
            )
        }

        func leaveTime(for block: DayPlanBlock, start: Date) -> Date? {
            guard let minutes = block.leaveReminderMinutesBefore, minutes > 0 else { return nil }
            return calendar.date(byAdding: .minute, value: -minutes, to: start)
        }

        if let current = scheduledBlocks.first(where: { block in
            guard let start = blockStart(block), let end = blockEnd(block) else { return false }
            return start <= now && now < end
        }), let end = blockEnd(current) {
            let next = scheduledBlocks.first { block in
                guard let start = blockStart(block) else { return false }
                return start > now && block.id != current.id
            }
            let nextStart = next.flatMap(blockStart)
            let nextLeaveTime: Date?
            if let next, let nextStart {
                nextLeaveTime = leaveTime(for: next, start: nextStart)
            } else {
                nextLeaveTime = nil
            }

            return TimeTrackingAttributes.ContentState(
                startTime: now,
                set: 0,
                heartRate: nil,
                dayPlanTitle: current.title,
                dayPlanNextTitle: next?.title ?? AppLanguageManager.shared.localizedString(forKey: "No more blocks"),
                dayPlanStatus: AppLanguageManager.shared.localizedString(forKey: "Now"),
                dayPlanCategory: current.categoryOption.localizedTitle,
                dayPlanEndTime: end,
                dayPlanNextStartTime: nextStart,
                dayPlanLeaveTime: nextLeaveTime.flatMap { $0 > now ? $0 : nil },
                dayPlanIsCurrentBlock: true
            )
        }

        guard let next = scheduledBlocks.first(where: { block in
            guard let start = blockStart(block) else { return false }
            return start > now
        }), let start = blockStart(next) else {
            return nil
        }

        let nextLeaveTime = leaveTime(for: next, start: start)
        if let nextLeaveTime {
            let leaveNow = nextLeaveTime <= now
            return TimeTrackingAttributes.ContentState(
                startTime: now,
                set: 0,
                heartRate: nil,
                dayPlanTitle: leaveNow
                    ? AppLanguageManager.shared.localizedString(forKey: "Leave now to be on time")
                    : next.title,
                dayPlanNextTitle: next.title,
                dayPlanStatus: AppLanguageManager.shared.localizedString(forKey: leaveNow ? "Leave now" : "Leave by"),
                dayPlanCategory: next.categoryOption.localizedTitle,
                dayPlanEndTime: leaveNow ? start : nextLeaveTime,
                dayPlanNextStartTime: start,
                dayPlanLeaveTime: leaveNow ? nil : nextLeaveTime,
                dayPlanIsCurrentBlock: false
            )
        }

        return TimeTrackingAttributes.ContentState(
            startTime: now,
            set: 0,
            heartRate: nil,
            dayPlanTitle: AppLanguageManager.shared.localizedString(forKey: "Open time"),
            dayPlanNextTitle: next.title,
            dayPlanStatus: AppLanguageManager.shared.localizedString(forKey: "Next"),
            dayPlanCategory: next.categoryOption.localizedTitle,
            dayPlanEndTime: start,
            dayPlanNextStartTime: start,
            dayPlanIsCurrentBlock: false
        )
    }
}
