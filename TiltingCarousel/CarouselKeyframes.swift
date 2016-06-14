//
//  CarouselKeyframes.swift
//  HardwireDemo
//
//  Created by Christian Schraga on 5/20/16.
//  Copyright © 2016 Straight Edge Digital. All rights reserved.
//

import Foundation
import UIKit


//Structure holds the view, its index and all its keyframe points

struct CarouselKeyframes {
    var goalRot:    CGFloat
    var item:       UIView
    var lPivotEnd:  CGFloat
    var lPivotBeg:  CGFloat
    var lFadeBeg:   CGFloat
    var lFadeEnd:   CGFloat
    var rPivotEnd:  CGFloat
    var rPivotBeg:  CGFloat
    var rFadeBeg:   CGFloat
    var rFadeEnd:   CGFloat
    var xCenter:    CGFloat
    var posIndex:   Int  //references position in superview
    var tagIndex:   Int  //to pass a reference to click delegate
    var position:   CGFloat {
        get {
            return item.layer.position.x
        }
    }
    
    init(){
        self.goalRot    = 0.0
        self.item       = UIView()
        self.lPivotEnd  = 0.0
        self.lPivotBeg  = 0.0
        self.lFadeBeg   = 0.0
        self.lFadeEnd   = 0.0
        self.rPivotEnd  = 0.0
        self.rPivotBeg  = 0.0
        self.rFadeEnd   = 0.0
        self.rFadeBeg   = 0.0
        self.xCenter    = 0.0
        self.posIndex   = 0
        self.tagIndex   = 0
        
    }
    
}
