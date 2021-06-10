//
//  MediaCreationManagerErrorChecking.swift
//  TINU
//
//  Created by Pietro Caruso on 08/10/2018.
//  Copyright © 2018 Pietro Caruso. All rights reserved.
//

import Cocoa

extension InstallMediaCreationManager{
	
	func installFinished(){
		
		DispatchQueue.global(qos: .background).async {
			
			//now the installer creation process has finished running, so our boolean must be false now
			cvm.shared.process.status = .postCreation
			
			DispatchQueue.main.async {
				
				//self.setActivityLabelText("Interpreting the results of the process")
				
				self.setActivityLabelText("activityLabel3")
				
			}
			
			log("process took \(UInt64(abs(cvm.shared.process.startTime.timeIntervalSinceNow))) seconds to finish")
			
			DispatchQueue.main.sync {
				//we have finished, so the controls opf the window are restored
				if let w = UIManager.shared.window{
					w.isMiniaturizeEnaled = true
					w.isClosingEnabled = true
					w.canHide = true
				}
			}
			
			//this code get's the output of teh process
			let outdata = cvm.shared.process.outputPipe.fileHandleForReading.readDataToEndOfFile()
			if var string = String(data: outdata, encoding: .utf8) {
				string = string.trimmingCharacters(in: .newlines)
				self.output = string.components(separatedBy: "\n")
			}
			
			//this code gets the errors of the process
			let errdata = cvm.shared.process.errorPipe.fileHandleForReading.readDataToEndOfFile()
			if var string = String(data: errdata, encoding: .utf8) {
				string = string.trimmingCharacters(in: .newlines)
				self.error = string.components(separatedBy: "\n")
			}
			
			//if there is a not normal code it will be logged
			log("\"\(cvm.shared.executableName)\" has finished")
			
			log("process output produced: ")
			
			if self.output.isEmpty{
				if let data = String(data: outdata, encoding: .utf8){
					log(data)
				}
			}else if self.output.first!.isEmpty{
				if let data = String(data: outdata, encoding: .utf8){
					log(data)
				}
			}else{
				
				//logs the output of the process
				for o in self.output{
					log("      " + o)
				}
				
			}
			
			//if the output is empty opr if it's just the standard output of the creation process, it's not logged
			if !self.error.isEmpty{
				if !((self.error.first?.contains("Erasing Disk: 0%... 10%... 20%... 30%...100%"))! && self.error.first == self.error.last){
					
					log("process error/s produced: ")
					//logs the errors produced by the process
					for o in self.error{
						log("      " + o)
					}
				}
			}else{
				if let data = String(data: errdata, encoding: .utf8){
					log("process error/s produced: ")
					log(data)
				}
			}
			
			self.analizeError()
		}
	}
	
	private struct CheckItem: Codable, Equatable{
		
		enum Operations: UInt8, Codable, Equatable{
			case contains = 0
			case equal = 1
			case different = 2
		}
		
		enum CheckValues: UInt8, Codable, Equatable{
			case fe = 0
			case me = 1
			case le = 2
			case lo = 3
			case llo = 4
			case tt = 5
			case rc = 6
			case px = 7
		}
		
		
		//var valuesToCheck: [String] = []
		var chackValues: [CheckValues] = []
		let stringsToCheck: [String?]
		let printMessage: String
		let message: String
		let notError: Bool
		
		var operation: Operations = .contains
		
		var isBack = false
		
	}
	
	private struct CheckItemCollection: CodableDefaults, Codable, Equatable{
		let itemsList: [CheckItem]
		internal static let defaultResourceFileName = "ErrorDecodingMessanges"
		internal static let defaultResourceFileExtension = "json"
	}
	
	private func analizeError(){
		
		DispatchQueue.global(qos: .background).async {
			
			//gets the termination status for comparison
			var rc = cvm.shared.process.process.terminationStatus
			
			//code used to test if the process has exited with an abnormal code
			if simulateAbnormalExitcode{
				rc = 1
			}
			
			//if the exit code produced is not normal, it's logged
			
			DispatchQueue.main.sync {
				//self.setActivityLabelText("Checking previous operations")
				self.setActivityLabelText("activityLabel4")
			}
			
			log("Checking the \(cvm.shared.executableName) process")
			
			if cvm.shared.installMac{
				//probably this will end up never executing
				DispatchQueue.main.sync {
					//102030100
					if (rc == 0){
						//self.viewController.goToFinalScreen(title: "macOS installed successfully", success: true)
						self.viewController.goToFinalScreen(id: "finalScreenMIS", success: true)
					}else{
						//self.viewController.goToFinalScreen(title: "macOS installation error: check the log for details", success: false)
						self.viewController.goToFinalScreen(id: "finalScreenMIE")
					}
					
				}
				
				return
			}
			
			var px = 0, fe: String!, me: String!, le: String!, lo: String!, llo: String!, tt: String!
			
			if !simulateCreateinstallmediaFailCustomMessage.isEmpty && simulateAbnormalExitcode{
				tt = simulateCreateinstallmediaFailCustomMessage
			}
			
			fe = self.error.first
			if self.error.indices.contains(1){
				me = self.error[1]
			}else{
				me = nil
			}
			le = self.error.last
			
			
			//fo = self.output.first
			lo = self.output.last
			
			llo = self.output.last?.lowercased()
			
			var mol = 1
			
			if le != nil{
				for c in le.reversed(){
					if c == ")"{
						px = 0
						mol = 1
					}
					
					if let n = Int(String(c)){
						px += n * mol;
						mol *= 10
					}
					
					if c == "("{
						break
					}
				}
			}
			
			
			let success = ((rc == 0) && (px == 0)) || (isRootUser && (px == 102030100) && (rc == 0)) //add rc to the root case
			
			log("Current user:                           \(NSUserName())")
			log("Main process exit code:                 \(px)")
			log("Sub process exit code produced:         \(rc)")
			log("Detected process outcome:               \(success ? "Positive" : "Negative")")
			
			let errorsList: [CheckItem] =  CodableCreation<CheckItemCollection>.createFromDefaultFile()!.itemsList
			
			var valueList: [CheckItem.CheckValues: String?] = [:]
			
			valueList[.px] = "\(px)"
			valueList[.rc] = "\(rc)"
			valueList[.fe] = fe
			valueList[.me] = me
			valueList[.le] = le
			valueList[.lo] = lo
			valueList[.llo] = llo
			valueList[.tt] = tt
			
			//sanity check print just so see how the json should look like
			print(CodableCreation<CheckItemCollection>.getEncoded(CheckItemCollection(itemsList: errorsList))!)
			
			//checks the conditions of the errorlist array to see if the operation has been complited with success
			print("Checking errors: ")
			for item in errorsList{
				
				var values: [String?] = []
				
				for nvalue in item.chackValues{
					
					if let value = valueList[nvalue] {
						values.append(value)
					}
					
				}
				
				print("    Strings to check: \(item.stringsToCheck)")
				print("    Strings to check against: \"\(values)\"")
				print("    Operation to perform: \(item.operation)")
				
				
				if !self.checkMatch(values, item.stringsToCheck, operation: item.operation){
					continue
				}
				
				print("    Check sucess")
				
				log("\n\(self.parse(messange: item.printMessage))\n")
				
				
				if item.notError{
					
					/*DispatchQueue.main.async {
					self.viewController.progress.isHidden = false
					self.viewController.spinner.isHidden = true
					}*/
					
					//here createinstall media succedes in creating the installer
					log("\(cvm.shared.executableName) process ended with success")
					log("Bootable macOS installer created successfully!")
					
					//extra operations here
					//trys to apply special options
					DispatchQueue.main.sync {
						//self.setActivityLabelText("Applaying custom options")
						self.setActivityLabelText("activityLabel5")
					}
					
					DispatchQueue.global(qos: .background).sync {
						
						if let res = self.manageSpecialOperations(){
							if !res{
								print("Advanced options failed")
							
								DispatchQueue.main.sync {
									//self.viewController.goToFinalScreen(title: "Error: Failed to apply advanced options", success: false)
									self.viewController.goToFinalScreen(id: "finalScreenAOE")
								}
							
								return
							}else{
								if item.isBack{
									DispatchQueue.main.sync {
										self.viewController.goBack()
									}
								}else{
									DispatchQueue.main.sync {
										self.viewController.goToFinalScreen(title: self.parse(messange: item.message), success: item.notError)
									}
								}
							}
						}
						
					}
					
				}else{
					if item.isBack{
						DispatchQueue.main.sync {
							self.viewController.goBack()
						}
					}else{
						DispatchQueue.main.sync {
							self.viewController.goToFinalScreen(title: self.parse(messange: item.message), success: item.notError)
						}
					}
				}
				
				
				return
			}
			
		}
		
	}
	
	private func checkMatch(_ stringsToCheck: [String?], _ valuesToCheck: [String?], operation: CheckItem.Operations) -> Bool{
		stringsfor: for ss in stringsToCheck{
			guard let s = ss else {
				continue stringsfor
			}
			
			if s == "" || s == " "{
				continue stringsfor
			}
			
			valuefor: for ovalueToCheck in valuesToCheck{
				
				guard let valueToCheck = ovalueToCheck else {
					continue valuefor
				}
				
				if valueToCheck == "" || valueToCheck == " "{
					continue valuefor
				}
				
				switch operation{
				case .contains:
					if s.contains(valueToCheck){
						return true
					}
					break
				case .different:
					
					if s != valueToCheck{
						return true
					}
					break
				case .equal:
					
					if s == valueToCheck{
						return true
					}
					break
				}
				
			}
		}
		
		return false
	}
	
	private func parse(messange: String) -> String{
		return TINU.parse(messange: messange, keys: ["{executable}": cvm.shared.executableName, "{drive}": self.dname])
	}
	
}
