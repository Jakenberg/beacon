//
//  SCHomeViewController.swift
//  Beacon
//
//  Created by Jake Peterson on 10/4/14.
//  Copyright (c) 2014 Jake Peterson. All rights reserved.
//

import UIKit

class SCInvisibleZoneButton:UIButton {
    var plusImageView:UIImageView!
    var myTitleLabel:UILabel!
    var defaultTitleText = "New Invisible Area"
    var active:Bool!
    
    override init(frame:CGRect) {
        super.init(frame: frame)
        
        let image = UIImage(named: "pluswhite")
        self.plusImageView = UIImageView(image: image)
        self.plusImageView.frame = CGRectMake(0, 0, image.size.width, image.size.height)
        self.plusImageView.userInteractionEnabled = false
        self.addSubview(self.plusImageView)
        
        self.myTitleLabel = UILabel()
        self.myTitleLabel.font = SCTheme.primaryFont(27)
        self.myTitleLabel.textColor = SCTheme.primaryTextColor
        self.myTitleLabel.text = self.defaultTitleText
        self.myTitleLabel.userInteractionEnabled = false
        self.addSubview(self.myTitleLabel)
        
        self.active = false
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let margin:CGFloat = 15
        
        self.plusImageView.frame = CGRectMake(margin, 0, self.plusImageView.bounds.size.width, self.plusImageView.bounds.size.height)
        var center = self.plusImageView.center
        center.y = self.bounds.size.height / 2
        self.plusImageView.center = center
        
        var frame = self.myTitleLabel.frame
        frame.origin.x = CGRectGetMaxX(self.plusImageView.frame) + 10
        frame.size.width = self.bounds.size.width - CGRectGetMinX(frame)
        frame.size.height = self.plusImageView.bounds.size.height
        self.myTitleLabel.frame = frame
        center = self.myTitleLabel.center
        center.y = self.bounds.size.height / 2
        self.myTitleLabel.center = center
    }
}

class SCHomeViewController: SCBeaconViewController {
    
    var tableView:UITableView!
    var socialToolbar:SCSocialIconsToolbar!
    var invisibleAreaButton:SCInvisibleZoneButton!
    var tableViewTag:Int = 10
    var cellHeight:CGFloat = 63.0
    var invisibleAreas:NSArray?
    var tableViewSeparator:CALayer!
    var newInvisibleAreaView:SCNewInvisibleAreaView!
    
    override func loadView() {
        super.loadView()
    
        let image = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("background", ofType: "jpg")!)
        let imageView = UIImageView(image: image)
        imageView.userInteractionEnabled = true
        self.view = imageView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView = UITableView(frame: CGRectZero, style: UITableViewStyle.Plain)
        self.tableView.dataSource = self
        self.tableView.separatorInset = UIEdgeInsetsZero
        self.tableView.separatorColor = UIColor.blackColor()
        self.tableView.delegate = self
        self.tableView.backgroundColor = UIColor.clearColor()
        self.tableView.backgroundView = nil
        self.tableView.opaque = true
        self.tableView.contentInset = UIEdgeInsetsZero
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        self.view.addSubview(self.tableView)
        
        self.tableViewSeparator = CALayer()
        self.tableViewSeparator.backgroundColor = UIColor.blackColor().CGColor
        self.tableView.layer.addSublayer(self.tableViewSeparator)
        
        let className = NSStringFromClass(UITableViewCell)
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: className)
        
        self.socialToolbar = SCSocialIconsToolbar(frame: CGRectMake(0, 0, 0, 70))
        self.socialToolbar.delegate = self
        self.socialToolbar.actionDelegate = self
        self.view.addSubview(self.socialToolbar)
        
        self.invisibleAreaButton = SCInvisibleZoneButton(frame: CGRectZero)
        self.invisibleAreaButton.addTarget(self, action: "toggleInvisibleArea", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(self.invisibleAreaButton)
        
        self.newInvisibleAreaView = SCNewInvisibleAreaView(frame: CGRectZero)
        
        self.getInvisibleZones()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: SCTheme.logoImageView)
        
        if let navigationBar = self.navigationController?.navigationBar {
            SCTheme.clearNavigation(navigationBar)
            
            self.socialToolbar.frame = CGRectMake(0, CGRectGetMaxY(navigationBar.frame), self.view.bounds.size.width, self.socialToolbar.bounds.size.height)
        }
        
        self.invisibleAreaButton.frame = CGRectMake(0, CGRectGetMaxY(self.socialToolbar.frame), self.view.bounds.size.width, 70)
        
        var frame = CGRectZero
        frame.origin.y = CGRectGetMaxY(self.invisibleAreaButton.frame)
        frame.size.width = self.view.bounds.size.width
        frame.size.height = self.view.bounds.size.height - CGRectGetMinY(frame)
        self.tableView.frame = frame
        
        self.tableViewSeparator.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 0.50)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.tableView.contentInset = UIEdgeInsetsZero
    }
    
    // MARK: - Getters
    
    func contentView(cell:UITableViewCell!, invisibleArea:SCInvisibleArea!) -> UIView {
        var view = UIView(frame: CGRectMake(0, 0, cell.bounds.size.width, self.cellHeight))
        view.backgroundColor = UIColor.clearColor()
        
        let margin:CGFloat = 15.0
        
        var deleteImage = UIImage(named: "xblack")
        var frame = CGRectMake(margin, margin, deleteImage.size.width, deleteImage.size.height)
        var deleteButton = UIButton(frame: frame)
        deleteButton.setImage(deleteImage, forState: UIControlState.Normal)
        view.addSubview(deleteButton)
        
        var x = CGRectGetMaxX(deleteButton.frame) + margin
        frame = CGRectMake(x, 7.5, view.bounds.size.width - (x + margin), 30)
        var titleLabel = UILabel(frame: frame)
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.font = SCTheme.primaryFont(25)
        titleLabel.text = invisibleArea.name
        view.addSubview(titleLabel)
        
        frame = CGRectMake(titleLabel.frame.origin.x, CGRectGetMaxY(titleLabel.frame), titleLabel.bounds.size.width, 17)
        var subtitleLabel = UILabel(frame: frame)
        let gray:CGFloat = 220.0/255.0
        subtitleLabel.textColor = UIColor(red: gray, green: gray, blue: gray, alpha: 1.0)
        subtitleLabel.font = SCTheme.primaryFont(15)
        subtitleLabel.text = invisibleArea.location
        view.addSubview(subtitleLabel)
        
        return view
    }
    
    // MARK: - Actions
    
    func getInvisibleZones() {
        if let user = SCUser.currentUser {
            self.invisibleAreaButton.myTitleLabel.text = "Loading..."
            self.invisibleAreaButton.plusImageView.hidden = true
            self.invisibleAreaButton.userInteractionEnabled = false
            
            SCUser.getUserProfile(user.id, completionHandler: { (responseObject, error) -> Void in
                if error == nil {
                    self.invisibleAreas = SCUser.currentUser?.invisibleAreas
                    self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
                }
                
                self.invisibleAreaButton.myTitleLabel.text = self.invisibleAreaButton.defaultTitleText
                self.invisibleAreaButton.plusImageView.hidden = false
                self.invisibleAreaButton.userInteractionEnabled = true
            })
        }
    }
    
    func deleteInvisibleArea(indexPath:NSIndexPath!) {
        self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        
        if let user = SCUser.currentUser {
            if let invisibleArea = self.invisibleAreas?.objectAtIndex(indexPath.row) as? SCInvisibleArea {
                SCUser.delete(invisibleArea, completionHandler: { (responseObject, error) -> Void in
                    if let user = SCUser.currentUser {
                        if let areas = self.invisibleAreas? {
                            self.invisibleAreas = areas
                            
                            if areas.count != user.invisibleAreas?.count {
                                self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
                            }
                        }
                    }
                })
            }
        }
    }
    
}

extension SCHomeViewController {
    
    func openInvisibleArea() {
        if let superview = self.newInvisibleAreaView.superview {
            self.newInvisibleAreaView.removeFromSuperview()
        }
        
        self.newInvisibleAreaView.layer.opacity = 0.0
        self.newInvisibleAreaView.frame = self.tableView.frame
        self.view.addSubview(self.newInvisibleAreaView)
        
        println(self.newInvisibleAreaView)
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.newInvisibleAreaView.layer.opacity = 1.0
        })
    }
    
    func closeInvisibleArea() {
        if self.newInvisibleAreaView.superview == nil {
            return
        }
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.newInvisibleAreaView.layer.opacity = 0.0
        }, completion:{ (success) -> Void in
            self.newInvisibleAreaView.removeFromSuperview()
        })
    }
    
    func toggleInvisibleArea() {
        if self.invisibleAreaButton.active == true {
            self.closeInvisibleArea()
        } else {
            self.openInvisibleArea()
        }
        self.invisibleAreaButton.active = !self.invisibleAreaButton.active
    }
    
}

extension SCHomeViewController: SCSocialDelegate {
    
    func buttonWasPressed(type:SocialType) {
        // TODO: We'll probably be putting a modal here
        SCUser.changeDefaultSocial(type, completionHandler: { (responseObject, error) -> Void in
            if error == nil {
                
            }
        })
    }
    
}

extension SCHomeViewController: UIToolbarDelegate {
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.TopAttached
    }
    
}

extension SCHomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = self.invisibleAreas?.count {
            return count
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return self.cellHeight
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let className = NSStringFromClass(UITableViewCell)
        var cell:UITableViewCell? = tableView.dequeueReusableCellWithIdentifier(className, forIndexPath: indexPath) as? UITableViewCell
        if (cell == nil) {
            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: className)
        }
        
        var invisibleArea:SCInvisibleArea? = self.invisibleAreas?.objectAtIndex(indexPath.row) as? SCInvisibleArea
        let view = self.contentView(cell, invisibleArea:invisibleArea)
        view.tag = self.tableViewTag
        cell?.contentView.addSubview(view)
        
        return cell!
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.layoutMargins = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero
        
        cell.backgroundColor = UIColor.clearColor()
        cell.separatorInset = UIEdgeInsetsZero
        cell.selectionStyle = UITableViewCellSelectionStyle.None
    }
    
    func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let view = cell.contentView.viewWithTag(self.tableViewTag) {
            view.removeFromSuperview()
        }
    }

    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String! {
        return "Delete"
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        self.deleteInvisibleArea(indexPath)
        return [NSObject()] // TODO: figure what to return here
    }
}
