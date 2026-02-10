//
//  TimerManager.swift
//  timer-tasks-mac
//
//  Created by Adrian Will on 2/6/26.
//

import Observation
import Foundation

@Observable
class TimerManager{
    static let shared = TimerManager()
    var activeTask: TimerTask?
    var timer: Timer?
    
    func start(task: TimerTask){
        self.activeTask = task
        timer?.invalidate()
        let interval: TimeInterval = 1
        timer = Timer
            .scheduledTimer(withTimeInterval: interval, repeats: true, block: { Timer in
                task.elapsedTime+=1
            })
    }
    func stop(){
        timer?.invalidate()
        timer=nil
        activeTask=nil
    }
}
