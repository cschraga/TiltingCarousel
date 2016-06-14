//
//  storage.swift
//  TiltingCarousel
//
//  Created by Christian Schraga on 6/14/16.
//  Copyright © 2016 Straight Edge Digital. All rights reserved.
//
/*
import UIKit

class storage: NSObject {
    func animatedCarouselMovement(velocity: CGFloat) {
        self.inMotion      = true
        
        let startPt        = carouselBase.layer.position.x
        let speed: CGFloat = max(abs(velocity) * 0.20, minSpeed) // it stalls the app if speed is too slow
        var duration       = 0.0
        
        //calculate end position with stopping distance formula d =kv2, and speed
        let animationDistance = velocityToDistance(velocity)
        var idealX     = velocity > 0 ? min(globalX + animationDistance, maxX) : max(globalX - animationDistance, minX)
        
        //find closest center point so that we always end up in the center
        idealX = closestCenterPt(idealX)
        positionIndex = getPosition(idealX)
        duration = Double(abs(idealX - globalX) / speed)
        
        //3. animate position
        let animationX = CASpringAnimation(keyPath: "position.x")
        animationX.fromValue        = startPt
        animationX.toValue          = idealX
        animationX.duration         = duration
        animationX.damping          = 8.0
        animationX.fillMode         = kCAFillModeBackwards
        animationX.delegate         = self
        animationX.setValue("motion", forKey: "type")
        print("my velocity: \(velocity), my duration: \(duration), ANIMATION settle time: \(animationX.settlingDuration), duration: \(animationX.duration), x:\(startPt) idealX: \(idealX)")
        carouselBase.layer.position.x  = idealX
        carouselBase.layer.addAnimation(animationX, forKey: "position")
        
        duration = animationX.settlingDuration < duration ? duration - animationX.settlingDuration : duration
        
        //4. animate rotation and fade
        for i in 0 ..< keyframedItems.count {
            
            //start and end rotation positions
            let start = atan2(keyframedItems[i].item.layer.transform.m31, keyframedItems[i].item.layer.transform.m11)
            let end     = calcRot(idealX, index: i)
            
            //start and end fade positions
            let anfang  = keyframedItems[i].item.layer.opacity
            let ende    = calcOpacity(idealX, index: i)
            
            //four keyframe points (in time)
            let denom = abs(idealX - globalX)
            
            //rotation
            let distA = keyframedItems[i].lPivotBeg - globalX
            let distB = keyframedItems[i].lPivotEnd - globalX
            let distC = keyframedItems[i].rPivotEnd - globalX
            let distD = keyframedItems[i].rPivotBeg - globalX
            var ratioA = CGFloat(0.0)
            var ratioB = CGFloat(0.0)
            var ratioC = CGFloat(0.0)
            var ratioD = CGFloat(0.0)
            
            //fade
            let distE = keyframedItems[i].lFadeEnd - globalX
            let distF = keyframedItems[i].lFadeBeg - globalX
            let distG = keyframedItems[i].rFadeBeg - globalX
            let distH = keyframedItems[i].rFadeEnd - globalX
            var ratioE = CGFloat(0.0)
            var ratioF = CGFloat(0.0)
            var ratioG = CGFloat(0.0)
            var ratioH = CGFloat(0.0)
            
            if denom != 0 {
                
                //rotation
                ratioA = velocity < 0 ? -distA / denom : distA / denom
                ratioB = velocity < 0 ? -distB / denom : distB / denom
                ratioC = velocity < 0 ? -distC / denom : distC / denom
                ratioD = velocity < 0 ? -distD / denom : distD / denom
                
                //fade
                ratioE = velocity < 0 ? -distE / denom : distE / denom
                ratioF = velocity < 0 ? -distF / denom : distF / denom
                ratioG = velocity < 0 ? -distG / denom : distG / denom
                ratioH = velocity < 0 ? -distH / denom : distH / denom
            }
            
            //rotation
            let timeA: CGFloat?  = ratioA >= 0.0 ? min(ratioA, 1.0) : nil
            let timeB: CGFloat?  = ratioB >= 0.0 ? min(ratioB, 1.0) : nil
            let timeC: CGFloat?  = ratioC >= 0.0 ? min(ratioC, 1.0) : nil
            let timeD: CGFloat?  = ratioD >= 0.0 ? min(ratioD, 1.0) : nil
            
            //fade
            let timeE: CGFloat?  = ratioE >= 0.0 ? min(ratioE, 1.0) : nil
            let timeF: CGFloat?  = ratioF >= 0.0 ? min(ratioF, 1.0) : nil
            let timeG: CGFloat?  = ratioG >= 0.0 ? min(ratioG, 1.0) : nil
            let timeH: CGFloat?  = ratioH >= 0.0 ? min(ratioH, 1.0) : nil
            
            print("layer:\(i) timeA:\(timeA) timeB:\(timeB) timeC:\(timeC) timeD:\(timeD) start:\(start) end:\(end)")
            
            var rotValues = [CGFloat]()
            var rotTimes  = [CGFloat]()
            
            var fadValues = [Float]()
            var fadTimes  = [CGFloat]()
            
            //set values and times
            if velocity < 0 {
                
                //animation
                if timeA != nil {
                    if timeB != nil {
                        if timeC != nil {
                            if timeD != nil {
                                //all have values
                                if timeD! == 1 {
                                    //do nothing
                                } else {
                                    if timeC! == 1 {
                                        rotValues = [rMaxRotation, start,  end]
                                        rotTimes  = [0,            timeD!, 1.0]
                                    } else {
                                        if timeB! == 1 {
                                            rotValues = [start, rMaxRotation, minRotation, end,    end]
                                            rotTimes  = [0,     timeD!,       timeC!,      timeB!, 1.0]
                                        } else {
                                            if timeA! == 1 {
                                                rotValues = [start, rMaxRotation, minRotation, minRotation, end]
                                                rotTimes  = [0,     timeD!,       timeC!,      timeB!,      1.0]
                                                
                                            } else {
                                                rotValues = [start, rMaxRotation, minRotation, minRotation, lMaxRotation, lMaxRotation]
                                                rotTimes  = [0, timeD!, timeC!, timeB!, timeA!, 1.0]
                                            }
                                            
                                        }
                                    }
                                }
                                
                            } else {
                                //timeA, timeB, timeC have values
                                if timeC! == 1.0 {
                                    rotValues = [start, end, end]
                                    rotTimes  = [0,     end, 1]
                                } else {
                                    rotValues = [start, minRotation, minRotation, end,    end]
                                    rotTimes  = [0,     timeC!,      timeB!,      timeA!, 1.0]
                                }
                            }
                        } else {
                            //timeA and timeB have values
                            if timeB! == 1.0 {
                                rotValues = [start, end, end]
                                rotTimes  = [0,     end, 1]
                            } else {
                                rotValues = [start, minRotation,  end, end]
                                rotTimes  = [0,     timeB!,    timeA!, 1]
                            }
                        }
                    } else {
                        //only timeA has a value
                        if timeA! == 1.0 {
                            rotValues = [start, end, end]
                            rotTimes  = [0, end, 1]
                        } else {
                            rotValues = [start, end, end]
                            rotTimes  = [0, timeA!, 1]
                        }
                    }
                } else {
                    //do nothing cause all nil
                }
                
                
                //fade
                if timeE != nil {
                    if timeF != nil {
                        if timeG != nil {
                            if timeH != nil {
                                //all have values
                                if timeH! == 1 {
                                    //do nothing
                                } else {
                                    if timeG! == 1 {
                                        fadValues = [minOp, anfang,  ende]
                                        fadTimes  = [0,     timeH!, 1.0]
                                    } else {
                                        if timeF! == 1 {
                                            fadValues = [anfang, minOp,  maxOp,  maxOp,  ende]
                                            fadTimes  = [0,      timeH!, timeG!, timeF!, 1.0]
                                        } else {
                                            if timeE! == 1 {
                                                fadValues = [anfang, minOp, maxOp,  maxOp,  ende]
                                                fadTimes  = [0,     timeH!, timeG!, timeF!, 1.0]
                                                
                                            } else {
                                                fadValues = [anfang, minOp, maxOp,  maxOp,  minOp, ende]
                                                fadTimes  = [0,     timeH!, timeG!, timeF!, timeE!, 1.0]
                                            }
                                            
                                        }
                                    }
                                }
                                
                            } else {
                                //timeE, timeF, timeG have values
                                if timeG! == 1.0 {
                                    fadValues = [anfang, ende, ende]
                                    fadTimes  = [0,     timeG!, 1]
                                } else {
                                    fadValues = [anfang, maxOp, maxOp,  minOp,  ende]
                                    fadTimes  = [0,     timeG!, timeF!, timeE!, 1.0]
                                }
                            }
                        } else {
                            //timeE and timeF have values
                            if timeF! == 1.0 {
                                fadValues = [anfang, ende, ende]
                                fadTimes  = [0,      timeF!, 1]
                            } else {
                                fadValues = [anfang, maxOp,    minOp,  ende]
                                fadTimes  = [0,     timeF!,    timeE!, 1]
                            }
                        }
                    } else {
                        //only timeE has a value
                        fadValues = [anfang, ende, ende]
                        fadTimes  = [0,    timeE!, 1]
                    }
                } else {
                    //do nothing cause all nil
                }
                
                
                
            } else {
                //positive velocity
                
                //rotation
                if timeD != nil {
                    if timeC != nil {
                        if timeB != nil {
                            if timeA != nil {
                                if timeA! == 1.0 {
                                    //do nothing
                                } else {
                                    //all have values
                                    
                                    if timeA! == 1 {
                                        //do nothing
                                    } else {
                                        if timeB! == 1 {
                                            //snap here... overshoots
                                            rotValues = [lMaxRotation,  start,         end]
                                            rotTimes  = [0,             timeA!,        1.0]
                                        } else {
                                            if timeC! == 1 {
                                                rotValues = [lMaxRotation, lMaxRotation, minRotation, end]
                                                rotTimes  = [0,            timeA!,       timeB!,      1.0]
                                            } else {
                                                if timeD! == 1 {
                                                    //snaps here
                                                    rotTimes = [0,      timeA!,       timeB!,      timeC!,      1.0]
                                                    rotValues = [start, lMaxRotation, minRotation, minRotation, end]
                                                } else {
                                                    rotValues = [start, lMaxRotation, minRotation, minRotation, rMaxRotation, rMaxRotation]
                                                    rotTimes  = [0,     timeA!,       timeB!,      timeC!,      timeD!,       1.0]
                                                }
                                                
                                                
                                            }
                                        }
                                    }
                                }
                            } else {
                                //b,c,d have values
                                if timeB! == 1.0 {
                                    rotValues = [start, end, end]
                                    rotTimes  = [0, end, 1]
                                } else {
                                    rotValues = [start, minRotation, minRotation, end,    end]
                                    rotTimes  = [0,     timeB!,      timeC!,      timeD!, 1.0]
                                }
                            }
                        } else {
                            //time c and d have values
                            if timeC! == 1.0 {
                                rotValues = [start, end, end]
                                rotTimes  = [0, end, 1]
                            } else {
                                //need to test this one
                                rotValues = [start, minRotation,  end,    end]
                                rotTimes  = [0,     timeC!,       timeD!,          1]
                            }
                        }
                    } else {
                        //only timeD has value
                        if timeD! == 1.0 {
                            rotValues = [start, end, end]
                            rotTimes  = [0,     end, 1.0]
                        } else {
                            rotValues = [start, end, end]
                            rotTimes  = [0, timeD!, 1.0]
                        }
                    }
                } else {
                    //do nothing
                }
                
                //fade
                if timeH != nil {
                    if timeG != nil {
                        if timeF != nil {
                            if timeE != nil {
                                if timeE! == 1.0 {
                                    //do nothing
                                } else {
                                    //all have values
                                    
                                    if timeE! == 1 {
                                        //do nothing
                                    } else {
                                        if timeF! == 1 {
                                            fadValues = [anfang,  minOp,  ende]
                                            fadTimes  = [0,       timeE!,  1.0]
                                        } else {
                                            if timeG! == 1 {
                                                fadValues = [anfang, minOp,  maxOp, ende]
                                                fadTimes  = [0,      timeE!, timeF!, 1.0]
                                            } else {
                                                if timeH! == 1 {
                                                    fadValues = [anfang, minOp,  maxOp,  maxOp,  ende]
                                                    fadTimes =  [0,      timeE!, timeF!, timeG!,  1.0]
                                                } else {
                                                    fadValues = [anfang, minOp,  maxOp,  maxOp,  minOp, ende]
                                                    fadTimes  = [0,      timeE!, timeF!, timeG!, timeH!, 1.0]
                                                }
                                                
                                                
                                            }
                                        }
                                    }
                                }
                            } else {
                                //f,g,h have values
                                if timeF! == 1.0 {
                                    fadValues = [anfang, ende, ende]
                                    fadTimes  = [0,    timeF!, 1]
                                } else {
                                    fadValues = [anfang, maxOp,  maxOp,  minOp,  ende]
                                    fadTimes  = [0,     timeF!, timeG!, timeH!,  1.0]
                                }
                            }
                        } else {
                            //time g and h have values
                            if timeG! == 1.0 {
                                fadValues = [anfang, ende,   ende]
                                fadTimes  = [0,      timeG!, 1]
                            } else {
                                //need to test this one
                                fadValues = [anfang, maxOp,  minOp,  ende]
                                fadTimes  = [0,     timeG!, timeH!, 1]
                            }
                        }
                    } else {
                        //only timeH has value
                        fadValues = [anfang, ende, ende]
                        fadTimes  = [0,    timeH!, 1.0]
                    }
                } else {
                    //do nothing
                }
                
            }
            
            //animate rotation
            let rotAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.y")
            rotAnimation.delegate = self
            rotAnimation.values   = rotValues
            rotAnimation.keyTimes = rotTimes
            rotAnimation.duration = duration
            rotAnimation.delegate = self
            rotAnimation.setValue("rotation", forKey: "type")
            rotAnimation.fillMode = kCAFillModeBackwards
            let timingFunction    = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseOut)
            rotAnimation.timingFunction = timingFunction
            
            //animate fade
            let fadAnimation      = CAKeyframeAnimation(keyPath: "opacity")
            fadAnimation.values   = fadValues
            fadAnimation.keyTimes = fadTimes
            fadAnimation.duration = duration
            fadAnimation.delegate = self
            fadAnimation.fillMode = kCAFillModeBackwards
            fadAnimation.timingFunction = timingFunction
            keyframedItems[i].item.layer.addAnimation(fadAnimation, forKey: "opacity")
            keyframedItems[i].item.layer.addAnimation(rotAnimation, forKey: "rotation")
            
            let group = CAAnimationGroup()
            group.animations = [rotAnimation, fadAnimation]
            group.duration   = Double(duration)
            keyframedItems[i].item.layer.addAnimation(group, forKey: "groupAnimation")
            
            var transform = CATransform3DIdentity
            transform.m34 = m34Max
            keyframedItems[i].item.layer.opacity = calcOpacity(idealX, index: i)
            keyframedItems[i].item.layer.transform = CATransform3DRotate(transform, end, 0.0, 1.0, 0.0)
        }
        
        
        
    }

}
*/