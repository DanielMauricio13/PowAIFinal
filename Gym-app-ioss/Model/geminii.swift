import ActivityKit
import Foundation

class LiveActivityManager {
    
    static let shared = LiveActivityManager()
    
    private var liveActivity: Activity<TimeTrackingAttributes>?
    
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
}
