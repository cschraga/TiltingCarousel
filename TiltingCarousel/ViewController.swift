//
//  ViewController.swift
//  TiltingCarousel
//
//  Created by Christian Schraga on 6/13/16.
//  Copyright © 2016 Straight Edge Digital. All rights reserved.
//

import UIKit

class ViewController: UIViewController, TiltingCarouselDataSource, TiltingCarouselDelegate {

    @IBOutlet weak var tiltingCarousel: TiltingCarousel!
    var views = [UIView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tiltingCarousel.delegate   = self
        tiltingCarousel.dataSource = self
        
        for i in 0 ..< 29 {
            let label = UILabel()
            label.font = label.font.fontWithSize(self.view.bounds.height * 0.25)
            label.backgroundColor = UIColor.blueColor()
            label.text = "\(i)"
            label.textAlignment = .Center
            label.alpha = 0.50
            views.append(label)
        }
        
        tiltingCarousel.loadData()
        tiltingCarousel.drawUI()
        print("loading carousel at \(tiltingCarousel.frame)")
    }
    
    
    func tcEntryCount(carousel: TiltingCarousel) -> Int {
        return views.count
    }
    
    func tcViewAtIndex(carousel: TiltingCarousel, index: Int) -> UIView {
        var result = UIView()
        if index < views.count {
            result = views[index]
        }
        return result
    }
    
    func tcCarouselClicked(carousel: TiltingCarousel, index: Int) {
        print("clicked \(index)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

