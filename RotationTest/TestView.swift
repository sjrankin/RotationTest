//
//  TestView.swift
//  RotationTest
//
//  Created by Stuart Rankin on 10/4/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

/// Wrapper around an SCNView to provide rotational test functionality.
class TestView: SCNView
{
    /// Initialize the test view.
    /// - Parameter BackgroundColor: View background color.
    /// - Parameter LineColor: Color of the grid lines.
    /// - Parameter CenterColor: Color of the center block.
    /// - Parameter CenterLine: Color of the (non-rotating) center lines.
    /// - Parameter Threshold: Used to calculate rotational error values.
    /// - Parameter ErrorLabel: Label used to show error values.
    /// - Parameter ResetEvery: How often to reset (delete then recreate) the grid and center block. Units are in rotations.
    ///                         If this value is 0, no resets occur.
    /// - Parameter RotateRight: Direction to rotate (true = right, false = left).
    func Initialize(BackgroundColor: UIColor, LineColor: UIColor, CenterColor: UIColor,
                    CenterLine: UIColor, Threshold: Float, ErrorLabel: UILabel,
                    ResetEvery: Int = 0, RotateRight: Bool = true)
    {
        RotateClockwise = RotateRight
        GridLineColor = LineColor
        CenterBlockColor = CenterColor
        ResetOnRotation = ResetEvery
        ErrorDeltaLabel = ErrorLabel
        ErrorThreshold = Threshold
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.borderWidth = 2.0
        self.scene = SCNScene()
        self.scene?.rootNode.addChildNode(MakeCamera())
        self.scene?.rootNode.addChildNode(MakeLight())
        self.backgroundColor = BackgroundColor
        MakeCenter(CenterColor)
        MakeGrid(LineColor)
        self.scene?.rootNode.addChildNode(GridNodes)
        MakeCenterLines(CenterLine)
        HideError()
    }
    
    /// Holds the direction to rotate. Also set by the parent view controller if the user changes the direction.
    var RotateClockwise: Bool = true
    
    /// Holds the color of grid lines. Used for when the scene is reset.
    var GridLineColor: UIColor = UIColor.systemPink
    
    /// Holds the color of the center block. Used for when the scene is reset.
    var CenterBlockColor: UIColor = UIColor.systemOrange
    
    /// Holds the current rotation count. Used to determine when to reset the scene.
    var CurrentRotationCount: Int = 0
    
    /// Holds the value that indicates when it is time to reset the scene. If 0, resets will not occur.
    var ResetOnRotation: Int = 0
    
    /// Recreate the parts of the scene that rotate. This is done as an experiment in using SCNAction.rotateBy with resetting
    /// the rotating part periodically to clear cumulative rotational errors from within SceneKit.
    func RecreateScene()
    {
        CenterNode.removeFromParentNode()
        CenterNode = SCNNode()
        MakeCenter(CenterBlockColor)
        GridNodes.removeFromParentNode()
        GridNodes = SCNNode()
        MakeGrid(GridLineColor)
        self.scene?.rootNode.addChildNode(GridNodes)
        CurrentRotationCount = 0
    }
    
    /// Holds the error threshold value.
    var ErrorThreshold: Float = 0.5
    
    /// Holds the error label to show error deltas.
    var ErrorDeltaLabel: UILabel!
    
    /// Create and return a camera node.
    /// - Returns: Node with a camera in it.
    func MakeCamera() -> SCNNode
    {
        let Camera = SCNCamera()
        Camera.fieldOfView = 92.5
        let Node = SCNNode()
        Node.camera = Camera
        Node.position = SCNVector3(0.0, 0.0, 10.0)
        return Node
    }
    
    /// Create and return a light node.
    /// - Returns: Node with a light in it.
    func MakeLight() -> SCNNode
    {
        let Light = SCNLight()
        Light.color = UIColor.white
        Light.type = .omni
        let Node = SCNNode()
        Node.light = Light
        Node.position = SCNVector3(-5.0, 5.0, 10.0)
        return Node
    }
    
    /// Make the center block. Add the center to the scene.
    /// - Parameter BoxColor: Color of the center block.
    func MakeCenter(_ BoxColor: UIColor)
    {
        OriginalCenterColor = BoxColor
        let Box = SCNBox(width: 6.0, height: 6.0, length: 1.0, chamferRadius: 0.0)
        Box.firstMaterial?.diffuse.contents = BoxColor
        Box.firstMaterial?.specular.contents = UIColor.white
        CenterNode = SCNNode(geometry: Box)
        CenterNode.position = SCNVector3(0.0, 0.0, 0.0)
        self.scene?.rootNode.addChildNode(CenterNode)
    }
    
    /// Original center block color. Used to reset the center block after an error condition clears.
    var OriginalCenterColor: UIColor = UIColor.black
    
    /// The center block node.
    var CenterNode: SCNNode = SCNNode()
    
    /// Set of grid lines.
    var GridNodes: SCNNode = SCNNode()
    
    /// Create a line from really thin boxes.
    /// - Parameter From: Starting point of the line.
    /// - Parameter To: Ending point of the line.
    /// - Parameter Color: The color of the line.
    /// - Parameter LineWidth: Width of the line (more accurately, the thickness).
    /// - Returns: A really thin box that functions visually as a line.
    func MakeLine(From: SCNVector3, To: SCNVector3, Color: UIColor, LineWidth: CGFloat = 0.01) -> SCNNode
    {
        var Width: Float = 0.01
        var Height: Float = 0.01
        let FinalLineWidth = Float(LineWidth)
        if From.y == To.y
        {
            Width = abs(From.x - To.x)
            Height = FinalLineWidth
        }
        else
        {
            Height = abs(From.y - To.y)
            Width = FinalLineWidth
        }
        let Line = SCNBox(width: CGFloat(Width), height: CGFloat(Height), length: 0.01,
                          chamferRadius: 0.0)
        Line.materials.first?.diffuse.contents = Color
        let Node = SCNNode(geometry: Line)
        Node.position = From
        Node.name = "GridNodes"
        return Node
    }
    
    /// Create and add two center lines to the scene.
    /// - Parameter LineColor: Color of the center lines.
    func MakeCenterLines(_ LineColor: UIColor)
    {
        let Width: CGFloat = 0.1
        let VLine = MakeLine(From: SCNVector3(0.0, 20.0, 0.0), To: SCNVector3(0.0, -80.0, 0.0), Color: LineColor,
                             LineWidth: Width)
        let HLine = MakeLine(From: SCNVector3(-20.0, 0.0, 0.0), To: SCNVector3(80.0, 0.0, 0.0), Color: LineColor,
                             LineWidth: Width)
        self.scene?.rootNode.addChildNode(VLine)
        self.scene?.rootNode.addChildNode(HLine)
    }
    
    /// Make the grid of lines that is intended to rotate to show effects of long-term rotations. Grid lines are placed
    /// in the `GridNodes` variable.
    /// - Parameter LineColor: The color of the line.
    func MakeGrid(_ LineColor: UIColor)
    {
        for Y in stride(from: 10.0, to: -10.1, by: -1.0)
        {
            let Start = SCNVector3(0.0, Y, 0.0)
            let End = SCNVector3(20.0, Y, 0.0)
            let LineNode = MakeLine(From: Start, To: End, Color: LineColor, LineWidth: 0.1)
            LineNode.name = "Horizontal,\(Int(Y))"
            GridNodes.addChildNode(LineNode)
        }
        for X in stride(from: -10.0, to: 10.1, by: 1.0)
        {
            let Start = SCNVector3(X, 0.0, 0.0)
            let End = SCNVector3(X, 20.0, 0.0)
            let LineNode = MakeLine(From: Start, To: End, Color: LineColor, LineWidth: 0.1)
            LineNode.name = "Vertical,\(Int(X))"
            GridNodes.addChildNode(LineNode)
        }
    }
    
    /// Determines if the passed radial value (converted to angles) is "bad" as defined as having a variance
    /// greater than `Threshold`.
    /// - Parameter Radian: The radian to verify for correctness.
    /// - Parameter Delta: On return, contains the delta value between the radian (converted to an angle) and 90°.
    func IsBadAngle(Radian: Float, Delta: inout Float) -> Bool
    {
        let Angle = abs(Radian * 180.0 / Float.pi)
        Delta = abs(Angle.remainder(dividingBy: 90.0))
        if Delta > ErrorThreshold
        {
            return true
        }
        return false
    }
    
    /// Hide the delta error label.
    func HideError()
    {
        DispatchQueue.main.async
            {
                self.ErrorDeltaLabel.alpha = 0
        }
    }
    
    /// Show the delta error label.
    /// - Parameter Delta: The delta value that indicates a rotational error.
    func ShowError(Delta: Float)
    {
        DispatchQueue.main.async
            {
                self.ErrorDeltaLabel.alpha = 1.0
                self.ErrorDeltaLabel.textColor = UIColor.yellow
                self.ErrorDeltaLabel.backgroundColor = UIColor.black
                self.ErrorDeltaLabel.text = "Error delta: \(Delta)"
        }
    }
    
    /// Half of pi, or, 90° for rotation.
    var HalfOfPi = CGFloat.pi / 2.0
    
    /// Test of the `SCNAction.rotateBy` SDK.
    /// - Note: This rotates appropriate nodes by -90° (in angles - converted to radians for actual usage) each call.
    /// - Parameter Duration: Duration of the rotation in seconds.
    func RotateBy(Duration: Double)
    {
        let ZRotation = HalfOfPi * (RotateClockwise ? -1.0 : 1.0)
        let Rotate = SCNAction.rotateBy(x: 0.0, y: 0.0, z: ZRotation, duration: Duration)
        GridNodes.runAction(Rotate)
        CenterNode.runAction(Rotate,
                             completionHandler:
            {
                if self.ResetOnRotation > 0
                {
                    self.CurrentRotationCount = self.CurrentRotationCount + 1
                    if self.CurrentRotationCount >= self.ResetOnRotation
                    {
                        self.RecreateScene()
                    }
                }
                var Z = self.CenterNode.eulerAngles.z
                var Delta: Float = 0.0
                let Bad = self.IsBadAngle(Radian: Z, Delta: &Delta)
                Z = Z * 180.0 / Float.pi * (self.RotateClockwise ? -1.0 : 1.0)
                if Bad
                {
                    if self.ResetOnRotation > 0
                    {
                                           print("Bad Z euler value in RotateByReset: Angle: \(Z)°, Delta: \(Delta)")
                    }
                    else
                    {
                    print("Bad Z euler value in RotateBy: Angle: \(Z)°, Delta: \(Delta)")
                    }
                    self.ShowError(Delta: Delta)
                    self.CenterNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                }
                else
                {
                    self.HideError()
                    self.CenterNode.geometry?.firstMaterial?.diffuse.contents = self.OriginalCenterColor
                }

        })
    }
    
    /// Test of the `SCNAction.rotateTo` SDK.
    /// - Note: The angle to rotate is calculated at each call and converted to radians for use.
    /// - Parameter Duration: Duration of the rotation in seconds.
    func RotateTo(Duration: Double)
    {
        ToAngle = ToAngle + 90.0
        if ToAngle > 270.0
        {
            ToAngle = 0.0
        }
        let ZRotation: CGFloat = (ToAngle * CGFloat.pi / 180.0) * (RotateClockwise ? -1.0 : 1.0)
        let Rotate = SCNAction.rotateTo(x: 0.0, y: 0.0, z: ZRotation, duration: Duration,
                                        usesShortestUnitArc: true)
        GridNodes.runAction(Rotate)
        CenterNode.runAction(Rotate,
                             completionHandler:
            {
                if self.ResetOnRotation > 0
                {
                    self.CurrentRotationCount = self.CurrentRotationCount + 1
                    if self.CurrentRotationCount >= self.ResetOnRotation
                    {
                        self.RecreateScene()
                    }
                }
                var Z = self.CenterNode.eulerAngles.z
                var Delta: Float = 0.0
                let Bad = self.IsBadAngle(Radian: Z, Delta: &Delta)
                Z = Z * 180.0 / Float.pi * (self.RotateClockwise ? -1.0 : 1.0)
                if Bad
                {
                    print("Bad Z euler value in RotateTo: Angle: \(Z)°, Delta: \(Delta)")
                    self.ShowError(Delta: Delta)
                    self.CenterNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                }
                else
                {
                    self.HideError()
                    self.CenterNode.geometry?.firstMaterial?.diffuse.contents = self.OriginalCenterColor
                }
        })
    }
    
    /// Holds the angle to rotate to in `RotateTo`.
    var ToAngle: CGFloat = 0.0
    
    /// 90° angles from 0 to 270 converted to radians (values generated in a Playground).
    let Radians: [CGFloat] = [0.0, 1.5707963267948966, 3.141592653589793, 4.71238898038469]
    /// Holds the index into `Radians` for each rotation.
    var RadialIndex = 0
    
    /// Test of the `SCNAction.rotateTo` SDK but with pre-calculated rotational values (in radians).
    /// - Note: Uses a set of pre-calculated rotational values to eliminate cumulative rounding errors.
    /// - Parameter Duration: Duration of the rotation in seconds.
    func RotateWith(Duration: Double)
    {
        RadialIndex = RadialIndex + 1
        if RadialIndex > Radians.count - 1
        {
            RadialIndex = 0
        }
        let RotationalRadians = Radians[RadialIndex] * (RotateClockwise ? -1.0 : 1.0)
        let Rotate = SCNAction.rotateTo(x: 0.0, y: 0.0, z: RotationalRadians, duration: Duration,
                                        usesShortestUnitArc: true)
        GridNodes.runAction(Rotate)
        CenterNode.runAction(Rotate,
                             completionHandler:
            {
                if self.ResetOnRotation > 0
                {
                    self.CurrentRotationCount = self.CurrentRotationCount + 1
                    if self.CurrentRotationCount >= self.ResetOnRotation
                    {
                        self.RecreateScene()
                    }
                }
                var Z = self.CenterNode.eulerAngles.z
                var Delta: Float = 0.0
                let Bad = self.IsBadAngle(Radian: Z, Delta: &Delta)
                Z = Z * 180.0 / Float.pi * (self.RotateClockwise ? -1.0 : 1.0)
                if Bad
                {
                    print("Bad Z euler value in RotateWith: Angle: \(Z)°, Delta: \(Delta)")
                    self.ShowError(Delta: Delta)
                    self.CenterNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                }
                else
                {
                    self.HideError()
                    self.CenterNode.geometry?.firstMaterial?.diffuse.contents = self.OriginalCenterColor
                }
        })
    }
}
