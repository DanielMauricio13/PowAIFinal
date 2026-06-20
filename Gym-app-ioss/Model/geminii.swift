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
        let contrent = ActivityContent(state: state, staleDate: nil)
        
        liveActivity = try?  Activity<TimeTrackingAttributes>.request(attributes: attriutes, content: contrent, pushType: nil)
    }
    
    func endLiveActivity(set:Int)  {
        let finalContentState = TimeTrackingAttributes.ContentState(startTime: .now, set: 1 )
        let finalContent = ActivityContent(state: finalContentState, staleDate: nil)
        
        Task {
            await liveActivity?.end(finalContent, dismissalPolicy: .immediate)
          
           // cancelNotification()
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
            staleDate: state.dayPlanEndTime
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

        if let current = scheduledBlocks.first(where: { block in
            guard let start = blockStart(block), let end = blockEnd(block) else { return false }
            return start <= now && now < end
        }), let end = blockEnd(current) {
            let next = scheduledBlocks.first { block in
                guard let start = blockStart(block) else { return false }
                return start > now && block.id != current.id
            }

            return TimeTrackingAttributes.ContentState(
                startTime: now,
                set: 0,
                heartRate: nil,
                dayPlanTitle: current.title,
                dayPlanNextTitle: next?.title ?? "No more blocks",
                dayPlanStatus: "Now",
                dayPlanCategory: current.categoryOption.title,
                dayPlanEndTime: end,
                dayPlanNextStartTime: next.flatMap(blockStart)
            )
        }

        guard let next = scheduledBlocks.first(where: { block in
            guard let start = blockStart(block) else { return false }
            return start > now
        }), let start = blockStart(next) else {
            return nil
        }

        return TimeTrackingAttributes.ContentState(
            startTime: now,
            set: 0,
            heartRate: nil,
            dayPlanTitle: "Open time",
            dayPlanNextTitle: next.title,
            dayPlanStatus: "Next",
            dayPlanCategory: next.categoryOption.title,
            dayPlanEndTime: start,
            dayPlanNextStartTime: start
        )
    }
}
