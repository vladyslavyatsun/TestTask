//
//  ViewController.swift
//  test
//
//  Created by mad on 07.12.2019.
//  Copyright © 2019 Vladyslav Yatsun. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var scaleView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var localTimerLabel: UILabel!
    @IBOutlet var globalTimerLabel: UILabel!

    private var timer: Timer?
    private var localTimeValue: Int = 0
    private var globalTimeValue: Int = 0

    private let dataManager = DataManager()
    private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }

    private func setup() {
        let defaultState = State.default
        self.titleLabel.text = defaultState.type.title
        self.scaleView.backgroundColor = defaultState.color
        self.scaleView.layer.borderWidth = 1.0
        self.scaleView.layer.borderColor = UIColor.black.cgColor
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.start(_:)))
        self.scaleView.addGestureRecognizer(gesture)
    }

    @objc func start(_ sender : UITapGestureRecognizer) {
        if self.operationQueue.operationCount == 0 {
            let operations = self.dataManager.states.map {
                return ShowStateOperation(state: $0, viewController: self)
            }
            self.operationQueue.addOperations(operations, waitUntilFinished: false)
            self.globalTimeValue = Int(self.dataManager.breatheStatesDuration)
        }
    }

    fileprivate func changeState(_ newState: State, completion: @escaping () -> Void) {
        self.scaleView.backgroundColor = newState.color

        switch newState.type {
        case .default:
            self.titleLabel.text = ""
            self.endTimer()
            self.scale(to: newState.type.scaleValue!, duration: newState.duration) {
                self.titleLabel.text = newState.type.title
                completion()
            }
        case .initial, .inhale, .exhale:
            self.titleLabel.text = newState.type.title
            self.scale(to: newState.type.scaleValue!, duration: newState.duration, completion: completion)
        case .hold:
            self.titleLabel.text = newState.type.title
            DispatchQueue.main.asyncAfter(wallDeadline: .now() + newState.duration, execute: completion)
        }

        self.localTimeValue = Int(newState.duration)
        if self.timer == nil && self.dataManager.isBreatheState(newState) {
            self.startTimer()
            self.updateTimerLables()
        }
    }

    fileprivate func scale(to value: CGFloat, duration: TimeInterval, completion: @escaping () -> Void) {
        UIView.animate(withDuration: duration, delay: 0.0, options: [], animations: {
            self.scaleView.transform = CGAffineTransform(scaleX: value, y: value)
        }, completion: { _ in
            completion()
        })
    }

}

extension ViewController {

    private func startTimer() {
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
    }

    @objc private func updateTime() {
        if self.localTimeValue > 0 {
            self.localTimeValue -= 1
        }
        if self.globalTimeValue > 0 {
            self.globalTimeValue -= 1
        }
        self.updateTimerLables()
    }

    private func updateTimerLables() {
        self.localTimerLabel.text = "\(self.timeFormatted(self.localTimeValue))"
        self.globalTimerLabel.text = "Remaining\n\(self.timeFormatted(self.globalTimeValue))"
    }

    private func endTimer() {
        self.localTimerLabel.text = ""
        self.globalTimerLabel.text = ""
        self.timer?.invalidate()
        self.timer = nil
    }

    private func timeFormatted(_ totalSeconds: Int) -> String {
        let seconds = totalSeconds % 60
        let minutes = (totalSeconds / 60) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

}

fileprivate class ShowStateOperation: Operation {
    private enum OperationState {
        case ready
        case executing
        case finished
    }

    private var operationState = OperationState.ready

    weak var viewController: ViewController?
    var state: State

    init(state: State, viewController: ViewController) {
        self.state = state
        self.viewController = viewController

        super.init()
    }

    override var isAsynchronous: Bool {
        return false
    }

    override var isExecuting: Bool {
        return self.operationState == .executing
    }

    override var isFinished: Bool {
        return self.operationState == .finished
    }

    override func main() {

        if self.isCancelled {
            return
        }

        DispatchQueue.main.async {
            guard let viewController = self.viewController else {
                self.operationState = .finished
                return
            }

            self.operationState = .executing
            viewController.changeState(self.state) {
                self.willChangeValue(forKey: "isFinished")
                self.operationState = .finished
                self.didChangeValue(forKey: "isFinished")
            }
        }
    }

}

