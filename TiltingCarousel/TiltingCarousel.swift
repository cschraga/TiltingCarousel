//
//  HWCarousel.swift
//  HardwireDemo
//
//  Created by Christian Schraga on 5/20/16.
//  Copyright © 2016 Straight Edge Digital. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

protocol CarouselPanDelegate {
    func carouselPanBegan(recognizer: CarouselPan)
}

class CarouselPan: UIPanGestureRecognizer {
    var panDelegate: CarouselPanDelegate?
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        panDelegate?.carouselPanBegan(self)
    }
}

protocol TiltingCarouselDataSource {

    func tcViewAtIndex(carousel:TiltingCarousel, index: Int) -> UIView
    func tcEntryCount(carousel:TiltingCarousel) -> Int
}

protocol TiltingCarouselDelegate {
    func tcCarouselClicked(carousel: TiltingCarousel, index: Int)
}

class TiltingCarousel: UIView, CarouselPanDelegate {

    //constants
    let lMaxRotation = CGFloat(M_PI / 2.0) * 0.90
    let rMaxRotation = -CGFloat(M_PI / 2.0) * 0.90
    let minRotation = CGFloat(0.0)
    let m34Max = CGFloat(-1 / 250.0)
    let cardWidthPct  = CGFloat(0.875)
    let cardHeightPct = CGFloat(0.875)
    var minSpeed      = CGFloat(150.0)
    var placeholderViews = 3
    var placeholderColor = UIColor(white: 0.25, alpha: 0.50)
    var springDamp     = 0.4
    var springVelocity = 0.8
    let dampingMultiplier = Double(10)
    let velocityMultiplier = Double(10)
    
    //layers
    var keyframedItems : [CarouselKeyframes]
    var carouselBase: UIView!
    var labelView: UILabel!
    var showLabel = true
    
    //delegates
    var dataSource: TiltingCarouselDataSource?
    var delegate: TiltingCarouselDelegate?

    //position indicators
    var globalX: CGFloat = 0.0
    var minX: CGFloat = -10.0
    var maxX: CGFloat = 10.0
    var inMotion = false {
        didSet{
            inMotion ? print("animation moving") : print("animation stopped")
        }
    }
    var positionIndex: Int {
        didSet {
            print("position index = \(positionIndex)")
        }
    }
    var cardCount: Int {
        return keyframedItems.count
    }
    
    //opacity settings
    let maxOp  = Float(1.0)
    let minOp  = Float(0.1)
    
    
    init(){
        positionIndex = 0
        keyframedItems = [CarouselKeyframes]()
        super.init(frame: CGRectZero)
        setup()
    }
    
    override init(frame: CGRect) {
        positionIndex = 0
        keyframedItems = [CarouselKeyframes]()
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        positionIndex = 0
        keyframedItems = [CarouselKeyframes]()
        super.init(coder: aDecoder)
        setup()
    }
    
    override func layoutSubviews() {
        drawUI()
    }
    
    func setup(){
        self.clipsToBounds = true
        self.contentMode = .ScaleAspectFill
        self.layer.bounds = self.frame
        self.layer.masksToBounds = true
        
        carouselBase = UIView()
        carouselBase.backgroundColor = UIColor.clearColor()
        carouselBase.userInteractionEnabled = true
        carouselBase.frame = self.bounds
        self.addSubview(carouselBase)
        
        for i in (0 ..< placeholderViews) {
            let aNewItem = UIView()
            aNewItem.backgroundColor = placeholderColor
            var kf = CarouselKeyframes()
            kf.tagIndex   = i
            carouselBase.addSubview(aNewItem)
            keyframedItems.append(kf)
        }
        
        let pan = CarouselPan(target: self, action: #selector(TiltingCarousel.handlePan(_:)))
        pan.panDelegate = self
        self.addGestureRecognizer(pan)
        
        
        let click = UITapGestureRecognizer(target: self, action: #selector(TiltingCarousel.handleClick(_:)))
        self.addGestureRecognizer(click)
        
    }
    
    func loadData() {
        if let dataDel = self.dataSource{
            let count = dataDel.tcEntryCount(self)
            //first make sure there is enough data to reload
            if count > 2 {
                for l in keyframedItems {
                    l.item.removeFromSuperview()
                }
                keyframedItems.removeAll()
                
                //now load new data
                for i in (0 ..< count) {
                    let aNewItem = dataDel.tcViewAtIndex(self, index: i)
                    var kf = CarouselKeyframes()
                    kf.item = aNewItem
                    kf.tagIndex = i
                    carouselBase.addSubview(aNewItem)
                    keyframedItems.append(kf)
                }
            }
            
        }
    }
    
    func drawUI(){
        
        carouselBase.frame = CGRectMake(0.0, 0.0, self.bounds.width, self.bounds.height)
        carouselBase.layer.anchorPoint = CGPointMake(0.0, 0.5)
        let w  = self.bounds.width  * cardWidthPct
        let h  = self.bounds.height * cardHeightPct
        var x  = self.bounds.midX - w / 2.0
        let y  = self.bounds.midY - h / 2.0
        
        for i in (0 ..< cardCount) {
            keyframedItems[i].item.layer.transform = CATransform3DIdentity
            keyframedItems[i].item.frame = CGRectMake(x,y,w,h)
            keyframedItems[i].item.layer.transform.m34 = m34Max
            keyframedItems[i].item.layer.anchorPoint = CGPointMake(0.5,0.5)
            keyframedItems[i].item.layer.opacity = 1.0
        }
    
        //place cards
        keyframedItems.sortInPlace({ (layer1, layer2) -> Bool in
            layer1.tagIndex < layer2.tagIndex
        })
        
        minX = CGFloat(0.0)
        maxX = CGFloat(0.0)
        
        for i in (0 ..< cardCount) {
            let odd = i % 2 != 0
            
            //odd left, even right
            if i == 0 {
                x = CGFloat(0.0)
                keyframedItems[0].xCenter   = 0.0
                keyframedItems[0].lPivotBeg = -w
                keyframedItems[0].rPivotBeg = w
                keyframedItems[0].lPivotEnd = -w/2.0
                keyframedItems[0].rPivotEnd = w/2.0
                
                keyframedItems[0].lFadeBeg = -5/8 * w
                keyframedItems[0].rFadeBeg =  5/8 * w
                keyframedItems[0].lFadeEnd = -3/4 * w
                keyframedItems[0].rFadeEnd =  3/4 * w
            } else {
                let round = ceil(CGFloat(i) / 2.0)
                x = odd ? -round * w : round * w
                let delta = odd ? w * round : -w * round
                //fill in keyframes
                keyframedItems[i].xCenter   = -x  //reverse signs to be consistent with global X measurement
                keyframedItems[i].lPivotBeg = keyframedItems[0].lPivotBeg + delta
                keyframedItems[i].rPivotBeg = keyframedItems[0].rPivotBeg + delta
                keyframedItems[i].lPivotEnd = keyframedItems[0].lPivotEnd + delta
                keyframedItems[i].rPivotEnd = keyframedItems[0].rPivotEnd + delta
                
                keyframedItems[i].lFadeBeg  = keyframedItems[0].lFadeBeg  + delta
                keyframedItems[i].rFadeBeg  = keyframedItems[0].rFadeBeg  + delta
                keyframedItems[i].lFadeEnd  = keyframedItems[0].lFadeEnd  + delta
                keyframedItems[i].rFadeEnd  = keyframedItems[0].rFadeEnd  + delta
            }
            
            //update min and max
            minX = keyframedItems[i].xCenter < minX ? keyframedItems[i].xCenter : minX
            maxX = keyframedItems[i].xCenter > maxX ? keyframedItems[i].xCenter : maxX
            
            keyframedItems[i].item.center = CGPointMake(self.bounds.midX + x, self.bounds.midY)
            
            //odds rotate clockwise, evens counterclockwise
            if i != 0 {
                let rot = odd ? lMaxRotation : rMaxRotation
                keyframedItems[i].item.layer.transform = CATransform3DRotate(keyframedItems[i].item.layer.transform, rot, 0.0, 1.0, 0.0)
            }
            
            
        }
        
        //calculate left to right order for containers
        keyframedItems.sortInPlace({ (layer1, layer2) -> Bool in
            layer1.position > layer2.position
        })
        
        for i in (0 ..< cardCount){
            keyframedItems[i].posIndex = i
        }
        
        positionIndex = getPosition(globalX)
    }

    
    func getPosition(centerX: CGFloat) -> Int{
        var result = 0
        if centerX <= minX {
            result =  0
        } else if centerX >= maxX {
            result = cardCount - 1
        } else {
            let halfWidth = self.bounds.width * cardWidthPct / 2.0
            for i in 0 ..< keyframedItems.count {
                let kfl = keyframedItems[i]
                let dtx = abs(kfl.xCenter - centerX)
                if dtx < halfWidth {
                    result = i
                }
            }
        }
        return result
    }
    
    func closestCenterPt(goalPt: CGFloat) -> CGFloat {
        var result = goalPt
        
        if goalPt <= minX {
            result =  keyframedItems[0].xCenter
        } else if goalPt >= maxX {
            result = keyframedItems[cardCount - 1].xCenter
        } else {
            let halfWidth = self.bounds.width * cardWidthPct / 2.0
            for i in 0 ..< keyframedItems.count {
                let kfl = keyframedItems[i]
                let dtx = abs(kfl.xCenter - goalPt)
                if dtx < halfWidth {
                    result = kfl.xCenter
                }
            }

        }
        
        return result
    }
    
    func calcRot(position:CGFloat, index:Int) -> CGFloat {
        var result = CGFloat(0.0)
        if index < keyframedItems.count{
            let kf = keyframedItems[index]
            let lpb = kf.lPivotBeg
            let lpe = kf.lPivotEnd
            let rpe = kf.rPivotEnd
            let rpb = kf.rPivotBeg
            if position <= lpb {
                return lMaxRotation
            } else if position > lpb && position < lpe {
                let denom = abs(lpe - lpb)
                if denom != 0.0 {
                    let pct = abs(position - lpe) / denom
                    //print("rotate \(pct)")
                    result = (pct) * lMaxRotation + (1 - pct) * minRotation
                }
            } else if position >= lpe && position <= rpe {
                result = minRotation
            } else if position > rpe && position < rpb {
                let denom = abs(rpe - rpb)
                if denom != 0.0 {
                    let pct = abs(position - rpe) / denom
                    //print("rotate \(pct)")
                    result = (pct) * rMaxRotation + (1-pct) * minRotation
                }
            } else {
                result = rMaxRotation
            }
            if abs(result) > 3.0 {
                //stop
            }
        }
        
        
        return result
        
    }
    
    func calcOpacity(position:CGFloat, index: Int) -> Float {
        var result = Float(1.0)
        if index < keyframedItems.count{
            let kf  = keyframedItems[index]
            let lfb = Float(kf.lFadeBeg)
            let lfe = Float(kf.lFadeEnd)
            let rfb = Float(kf.rFadeBeg)
            let rfe = Float(kf.rFadeEnd)
            let gx  = Float(position)
            
            if gx <= lfe {
                // invisible to the left
                result = minOp
                
            } else if gx > lfe && gx < lfb {
                // fade to the left
                let denom = abs(lfb - lfe)
                result = (abs(gx - lfb) * minOp ) / denom + (abs(gx - lfe) * maxOp ) / denom
                
            } else if gx >= lfb && gx <= rfb {
                // full visibility in the middle
                result = maxOp
                
            } else if gx > rfb && gx < rfe {
                // fade to the right
                let denom = abs(rfb - rfe)
                result = (abs(gx - rfb) * minOp ) / denom + (abs(gx - rfe) * maxOp ) / denom
                
            } else if gx >= rfe {
                // invisible to the right
                result = minOp
                
            }
            
        }
        
        return result
    }
    
    func handlePan(recognizer: UIPanGestureRecognizer){
        let translation = recognizer.translationInView(self).x
        let a = carouselBase.frame.origin.x
        let b = self.frame.origin.x
        globalX = a - b
        print("x is \(globalX)")
        
        if recognizer.state == .Changed {
            moveCarousel(translation)
            recognizer.setTranslation(CGPointZero, inView: self)
        }
        
        
        if recognizer.state == .Ended {
            animatedCarouselMovement(recognizer.velocityInView(self).x)
        }
    }
    
    func handleClick(recognizer: UITapGestureRecognizer) {
        
        if inMotion {
            //do nothing
        } else {
            var index = positionIndex
            index = keyframedItems[positionIndex].tagIndex
            delegate?.tcCarouselClicked(self, index: index)
        }
        
    }

    
    func carouselPanBegan(recognizer: CarouselPan) {
        print("stop animation")
    
        //stop animation if in progress
        if inMotion {
            //calculate position when stopped
            carouselBase.layer.position = carouselBase.layer.presentationLayer()!.position
            let a = carouselBase.frame.origin.x
            let b = self.frame.origin.x
            globalX = a - b
            print("x is \(globalX)")
            
            //remove position animation
            carouselBase.layer.removeAnimationForKey("position")
            
            //remove animation from each layer and replace it with regular rotation transform based on position
            var transform = CATransform3DIdentity
            transform.m34 = m34Max
            for item in keyframedItems {
                item.item.layer.removeAnimationForKey("rotation")
                item.item.layer.removeAnimationForKey("opacity")
                let rotPct  = calcRot(globalX, index: item.posIndex)
                item.item.layer.opacity = calcOpacity(globalX, index: item.posIndex)
                item.item.layer.transform = CATransform3DRotate(transform, rotPct, 0.0, 1.0, 0.0)
            }
            
            inMotion = false
        }
    }
    
    func moveCarousel(distance: CGFloat) {
        let a = carouselBase.frame.origin.x
        let b = self.frame.origin.x
        globalX = a - b
        let newPos = distance + globalX
        
        //move carousel base
        carouselBase.center.x = carouselBase.center.x + distance
        positionIndex = getPosition(newPos)  //keep track of center index
        
        //animate rotation and fade
        var transform = CATransform3DIdentity
        transform.m34 = m34Max
    
        for item in keyframedItems {
            let rotPct  = calcRot(globalX,     index: item.posIndex)
            let fadePct = calcOpacity(globalX, index: item.posIndex)
            item.item.layer.transform = CATransform3DRotate(transform, rotPct, 0.0, 1.0, 0.0)
            item.item.layer.opacity   = fadePct
        }
        
    }
    
    func velocityToDistance(velocity: CGFloat) -> CGFloat {
        var result = CGFloat(0.0)
        let friction = CGFloat(0.00005)
        result = friction * pow(velocity, 2.0)
        return result
    }
    
    func animatedCarouselMovement(velocity: CGFloat) {
        self.inMotion      = true
        
        let startPt        = carouselBase.layer.position.x
        let speed: CGFloat = max(abs(velocity) * 0.20, minSpeed) // it stalls the app if speed is too slow
        var duration       = 0.0
        
        //calculate end position and duration
        let animationDistance = velocityToDistance(velocity)
        var idealX     = velocity > 0 ? min(globalX + animationDistance, maxX) : max(globalX - animationDistance, minX)
        idealX = closestCenterPt(idealX)
        positionIndex = getPosition(idealX)
        duration = Double(abs(idealX - globalX) / speed)
        print("animate move from: \(startPt) to: \(idealX)")
        
        //setup matrix for keyframe animations
        var positions = [Double]()
        var rotations = [Double]()
        var opacities = [Double]()
        
        //animate position (easy)
        positions = SpringAnimation.animationValues(Double(startPt), toValue: Double(idealX), usingSpringWithDamping: springDamp * dampingMultiplier, initialSpringVelocity: springVelocity * velocityMultiplier)
        let posAnimation = CAKeyframeAnimation(keyPath: "position.x")
        posAnimation.values = positions
        posAnimation.duration = duration
        posAnimation.delegate = self
        posAnimation.setValue("motion", forKey: "type")
        carouselBase.layer.position.x  = idealX
        carouselBase.layer.addAnimation(posAnimation, forKey: "position")
        
        //animate each layer (hard)
        for item in keyframedItems {
            rotations.removeAll()
            opacities.removeAll()
            for position in positions {
                let rot = Double(calcRot(CGFloat(position), index: item.posIndex))
                let op  = Double(calcOpacity(CGFloat(position), index: item.posIndex))
                rotations.append(rot)
                opacities.append(op)
            }
            
            //animate rotation
            let rotAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.y")
            rotAnimation.delegate = self
            rotAnimation.values   = rotations
            rotAnimation.duration = duration
            rotAnimation.delegate = self
            rotAnimation.setValue("rotation", forKey: "type")
            
            //animate fade
            let fadAnimation      = CAKeyframeAnimation(keyPath: "opacity")
            fadAnimation.values   = opacities
            fadAnimation.duration = duration
            fadAnimation.delegate = self
            fadAnimation.setValue("opacity", forKey: "type")
            item.item.layer.addAnimation(fadAnimation, forKey: "opacity")
            item.item.layer.addAnimation(rotAnimation, forKey: "rotation")
            
            var transform = CATransform3DIdentity
            transform.m34 = m34Max
            item.item.layer.opacity = calcOpacity(idealX, index: item.posIndex)
            let finalRot = calcRot(idealX, index: item.posIndex)
            item.item.layer.transform = CATransform3DRotate(transform, finalRot, 0.0, 1.0, 0.0)
            
        }
        
    }
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        if flag {
            if let val = anim.valueForKey("type") as? String {
                if val == "motion" {
                    print("movement stopped")
                    self.inMotion = false
                }
            }
        }
    }

}
