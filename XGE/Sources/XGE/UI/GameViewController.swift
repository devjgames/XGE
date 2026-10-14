//
//  GameViewController.swift
//  XGE
//
//  Created by Douglas McNamara on 2/15/26.
//

import AppKit
import simd
import MetalKit
import XGE
import JavaScriptCore

@MainActor
func unproject(z: Float) -> Vec3 {
    if let gameView = GameView.instance {
        let m = simd_inverse(gameView.scene.projection * gameView.scene.view)
        let w = Float(gameView.frame.size.width)
        let h = Float(gameView.frame.size.height)
        let x = gameView.mouseX
        let y = gameView.mouseY
        var v = Vec4()

        v.x = 2 * (x - 0) / w - 1
        v.y = 2 * (y - 0) / h - 1
        v.z = 2 * z - 1
        v.w = 1
        v = m * v
        v /= v.w
        
        return Vec3(v.x, v.y, v.z)
    }
    return Vec3(0, 0, 0)
}

@MainActor
class GameViewController {
    
    public var selectedNode: Node?
    public var mode = 0
    
    private var _down1 = false
    private var _down2 = false
    
    public init() {
    }
    
    public func handleInput() -> Int? {
        var selectedIndex:Int?
        
        if let gameView = GameView.instance {
            if gameView.isButtonDown(button: 0) {
                if mode == 0 { // zoom
                    gameView.scene.zoom()
                } else if mode == 1 { // pan xz
                    let x = gameView.scene.eye - gameView.scene.target
                    var f = gameView.scene.eye - gameView.scene.target
                    
                    f.y = 0
                    
                    if simd_length(f) > 0.0000001 {
                        f = simd_normalize(f)
                        let r = simd_normalize(simd_cross(f, Vec3(0, 1, 0)))
                        
                        gameView.scene.target += f * gameView.deltaY + r * gameView.deltaX
                        gameView.scene.eye = gameView.scene.target + x
                    }
                } else if mode == 2 { // sel
                    if !_down1 {
                        let orig = unproject(z: 0)
                        let dir = simd_normalize(unproject(z: 1) - orig)
                        var time = Float.greatestFiniteMagnitude
                        var node:Node?
                        
                        _pickTri = -1
                        
                        for i in (0..<gameView.scene.root.childCount) {
                            let child = gameView.scene.root[i]

                            if child.data["followEye"] == nil {
                                if gameView.scene.pick(root: child, node: child, orig: orig, dir: dir, time: &time) {
                                    node = child
                                }
                            }
                        }
                        selectedNode = node
                        
                        if let selectedNode = selectedNode {
                            for i in (0..<gameView.scene.root.childCount) {
                                if selectedNode === gameView.scene.root[i] {
                                    selectedIndex = i
                                }
                            }
                        } else {
                            selectedIndex = -1
                        }
                    }
                } else if let selected = selectedNode {
                    if mode == 3 { // move xz
                        var f = gameView.scene.eye - gameView.scene.target
                        
                        f.y = 0
                        
                        if simd_length(f) > 0.0000001 {
                            f = simd_normalize(f)
                            let r = simd_normalize(simd_cross(f, Vec3(0, 1, 0)))
                            
                            selected.position += f * -gameView.deltaY + r * -gameView.deltaX
                        }
                    } else if mode == 4 { // rot x
                        selected.rotate(axis: 0, degrees: gameView.deltaX)
                    } else if mode == 5 { // rot y
                        selected.rotate(axis: 1, degrees: gameView.deltaX)
                    } else if mode ==  6 { // rot z
                        selected.rotate(axis: 2, degrees: gameView.deltaX)
                    }
                }
                _down1 = true
            } else {
                if let selectedNode = selectedNode {
                    if mode == 3 && _down1 {
                        selectedNode.position = gameView.scene.snap(selectedNode.position)
                    }
                }
                if mode == 1 && _down1 {
                    let x = gameView.scene.eye - gameView.scene.target
                    
                    gameView.scene.target = gameView.scene.snap(gameView.scene.target)
                    gameView.scene.eye = gameView.scene.target + x
                }
                _down1 = false
            }
            if gameView.isButtonDown(button: 1) {
                if mode == 0 {
                    gameView.scene.rotateAroundTarget()
                } else if mode == 1 { // pan y
                    let x = gameView.scene.eye - gameView.scene.target
                    
                    gameView.scene.target += Vec3(0, -gameView.deltaY, 0)
                    gameView.scene.eye = gameView.scene.target + x
                } else if let selected = selectedNode {
                    if mode == 3 { // move y
                        selected.position += Vec3(0, gameView.deltaY, 0)
                    }
                }
                _down2 = true
            } else {
                if let selectedNode = selectedNode {
                    if mode == 3 && _down2 {
                        selectedNode.position = gameView.scene.snap(selectedNode.position)
                    }
                }
                if mode == 1 && _down2 {
                    let x = gameView.scene.eye - gameView.scene.target
                    
                    gameView.scene.target = gameView.scene.snap(gameView.scene.target)
                    gameView.scene.eye = gameView.scene.target + x
                }
                _down2 = false
            }
        }
        return selectedIndex
    }
}
