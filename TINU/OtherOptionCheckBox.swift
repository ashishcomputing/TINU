//
//  OtherOptionsItem.swift
//  TINU
//
//  Created by ITzTravelInTime on 14/11/17.
//  Copyright © 2017 Pietro Caruso. All rights reserved.
//

import Cocoa

class OtherOptionsCheckBox: NSView {
    
	var optionID: CreationProcess.OptionsManager.ID!
	
    var checkBox = NSButton()
	
	var infoButton = NSButton()
	
	//let mlength = "Delete the .IAPhisicalMedia file (Fixes USB installer no".characters.count

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
		
		let option = cvm.shared.options.list[optionID ?? .unknown]
		
		checkBox.setButtonType(.switch)
		checkBox.title = option?.description.title ?? "[Error: no option specified]"
		checkBox.target = self
		checkBox.action = #selector(OtherOptionsCheckBox.checked)
		
		checkBox.isEnabled = option?.isUsable ?? false
		
		checkBox.state = (option?.isActivated ?? false) ? .on : .off
		
		checkBox.font = NSFont.systemFont(ofSize: 13)
		
        checkBox.frame.origin = NSPoint(x: 10, y: 7)
        checkBox.frame.size = NSSize(width: self.frame.size.width - 30, height: 16)

        self.addSubview(checkBox)
		
		infoButton.title = ""
		infoButton.bezelStyle = .helpButton
		
		infoButton.frame.size = NSSize(width: 25, height: 25)
		
		infoButton.frame.origin = NSPoint(x: self.frame.size.width - 25, y: 2.5)
		
		infoButton.font = NSFont.systemFont(ofSize: 13)
		infoButton.isContinuous = true
		infoButton.target = self
		infoButton.action = #selector(OtherOptionsCheckBox.showInfo)
		
		self.addSubview(infoButton)
    }
	
	@objc func checked(){
		
		if optionID == nil{
			return
		}
		
		log("Trying to change the value of option \"\(optionID!)\"")
		
		if cvm.shared.options.list[optionID!] == nil { return }
		
		let newState = (checkBox.state.rawValue == 1)
		
		//this as been done in this way instead of an if var because of possible errors
		cvm.shared.options.list[optionID!]?.isActivated = newState
		
		//this code here is used to deactivate the APFS convertion stuff if the user has choosen to format the target drive
		if !cvm.shared.installMac || !cvm.shared.disk.isAPFS || (optionID! != CreationProcess.OptionsManager.ID.forceToFormat){
			return
		}
		
		for item in self.superview!.subviews{
			guard let opt = item as? OtherOptionsCheckBox else { continue }
			
			if opt.optionID == nil{
				continue
			}
			
			if opt.optionID != CreationProcess.OptionsManager.ID.notUseApfs{
				continue
			}
			
			cvm.shared.options.list[optionID]?.isActivated = newState
			cvm.shared.options.list[optionID]?.isUsable = newState
			opt.checkBox.isEnabled = newState
			opt.checkBox.state = checkBox.state
		}
	}
	
	@objc func showInfo(){
		let vc = UIManager.shared.storyboard.instantiateController(withIdentifier: "OtherOptionInfoViewController") as! OtherOptionsInfoViewController
		
		vc.optionID = optionID
		
		CustomizationWindowManager.shared.referenceWindow.contentViewController?.presentAsSheet(vc)
		
	}
}
