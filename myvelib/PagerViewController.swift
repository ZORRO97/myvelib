//
//  PagerViewController.swift
//  myvelib
//
//  Created by etudiant-11 on 14/04/2016.
//  Copyright © 2016 francois. All rights reserved.
//

import UIKit

class PagerViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    var pages = [UIViewController]()
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?
    {
        let currentIndex = pages.indexOf(viewController)!
        
        if (currentIndex == 0) {
            return nil
        } else {
            return pages[currentIndex-1]
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        let currentIndex = pages.indexOf(viewController)!
        
        if (currentIndex == pages.count-1) {
            return nil
            
        } else {
            return pages[currentIndex+1]
        }
    }
    
    /*
     func presentationCountForPageViewController(pageViewController: UIPageViewCont
     roller) -> Int {
     return pages.count
     }
     func presentationIndexForPageViewController(pageViewController: UIPageViewCont
     roller) -> Int {
     return 0
     }
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.dataSource = self
        let p0 : MainViewController = (self.storyboard?.instantiateViewControllerWithIdentifier("page0")) as! MainViewController
        let p1 : MainViewController = (self.storyboard?.instantiateViewControllerWithIdentifier("page0"))! as! MainViewController
        let p2 : MainViewController = (self.storyboard?.instantiateViewControllerWithIdentifier("page0"))! as! MainViewController
        p0.pageIndex = .Home
        p1.pageIndex = .Work
        p2.pageIndex = .Geoloc
        pages = [p0, p1, p2]
        setViewControllers([p0], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)
        
    }
}
