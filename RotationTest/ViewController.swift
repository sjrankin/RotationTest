//
//  ViewController.swift
//  RotationTest
//
//  Created by Stuart Rankin on 10/4/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import UIKit
import Foundation
import SceneKit

/// Code to control the main UI.
class ViewController: UIViewController
{
    /// Initialize views.
    override func viewDidLoad()
    {
        super.viewDidLoad()
        InitializeViews(ErrorThreshold: 0.1)
        Start()
    }
    
    /// Initialize the three rotational views.
    /// - Parameter ErrorThreshold: Value to determine when an error in rotation occurs.
    func InitializeViews(ErrorThreshold: Float)
    {
        let DirIndex = UserDefaults.standard.integer(forKey: "DirectionIndex")
        DirectionSegment.selectedSegmentIndex = DirIndex
        let InitialDirection = DirIndex == 0
        RotateByView.Initialize(BackgroundColor: UIColor.red, LineColor: UIColor.white,
                                CenterColor: UIColor.cyan, CenterLine: UIColor.yellow,
                                Threshold: ErrorThreshold, ErrorLabel: RotateByError,
                                RotateRight: InitialDirection)
        RotateToView.Initialize(BackgroundColor: UIColor.green, LineColor: UIColor.black,
                                CenterColor: UIColor.magenta, CenterLine: UIColor.black,
                                Threshold: ErrorThreshold, ErrorLabel: RotateToError,
                                RotateRight: InitialDirection)
        RotateWithArrayView.Initialize(BackgroundColor: UIColor.blue, LineColor: UIColor.white,
                                       CenterColor: UIColor.yellow, CenterLine: UIColor.cyan,
                                       Threshold: ErrorThreshold, ErrorLabel: RotateWithError,
                                       RotateRight: InitialDirection)
        RotateByResetView.Initialize(BackgroundColor: UIColor(red: 0.75, green: 0.2, blue: 0.2, alpha: 1.0),
                                 LineColor: UIColor.white, CenterColor: UIColor.black,
                                 CenterLine: UIColor.yellow, Threshold: ErrorThreshold,
                                 ErrorLabel: RotateByResetError, ResetEvery: 10,
                                 RotateRight: InitialDirection)
    }
    
    /// Starts the second timer (which also controls the rotations).
    func Start()
    {
        let _ = Timer.scheduledTimer(timeInterval: 1.0, target: self,
                                     selector: #selector(HandleElapsedSeconds),
                                     userInfo: nil, repeats: true)
    }
    
    /// Increment the number of elapsed seconds and call the appropriate rotation function for
    /// each view.
    @objc func HandleElapsedSeconds()
    {
        SecondCount = SecondCount + 1
        ElapsedSecondsLabel.text = "\(SecondCount)"
        RotateByView.RotateBy(Duration: 0.25)
        RotateByResetView.RotateBy(Duration: 0.25)
        RotateToView.RotateTo(Duration: 0.25)
        RotateWithArrayView.RotateWith(Duration: 0.25)
        let CountString = "Rotations: \(SecondCount)"
        RotateWithCountLabel.text = CountString
        RotateToCountLabel.text = CountString
        RotateByCountLabel.text = CountString
        RotateByResetCountLabel.text = CountString
    }
    
    /// Holds the number of elapsed seconds.
    var SecondCount: Int = 0

    /// Handle changes to the dirction segment.
    @IBAction func HandleChangedDirection(_ sender: Any)
    {
        RotateByView.RotateClockwise = DirectionSegment.selectedSegmentIndex == 0
        RotateByResetView.RotateClockwise = DirectionSegment.selectedSegmentIndex == 0
        RotateToView.RotateClockwise = DirectionSegment.selectedSegmentIndex == 0
        RotateWithArrayView.RotateClockwise = DirectionSegment.selectedSegmentIndex == 0
        UserDefaults.standard.set(DirectionSegment.selectedSegmentIndex, forKey: "DirectionIndex")
    }
    
    // MARK: Interface builder outlets.
    
    @IBOutlet weak var RotateWithError: UILabel!
    @IBOutlet weak var RotateToError: UILabel!
    @IBOutlet weak var RotateByError: UILabel!
    @IBOutlet weak var ElapsedSecondsLabel: UILabel!
    @IBOutlet weak var RotateWithCountLabel: UILabel!
    @IBOutlet weak var RotateToCountLabel: UILabel!
    @IBOutlet weak var RotateByCountLabel: UILabel!
    @IBOutlet weak var RotateByView: TestView!
    @IBOutlet weak var RotateToView: TestView!
    @IBOutlet weak var RotateWithArrayView: TestView!
    @IBOutlet weak var RotateByResetView: TestView!
    @IBOutlet weak var RotateByResetError: UILabel!
    @IBOutlet weak var RotateByResetCountLabel: UILabel!
    @IBOutlet weak var DirectionSegment: UISegmentedControl!
}

