//
//  MainTabController.swift
//  ITHelpApp-iOS
//
//  Created by Johan Adami on 10/7/15.
//  Copyright © 2015 Johan Adami. All rights reserved.
//

import UIKit
import PubNub
import Parse

var alertedTicketId: String?
var alertedTicket: PFObject?

class MainTabController: UITabBarController, PNObjectEventListener {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AppConstants.requestHandler = PubnubHandler(pubKey: AppConstants.pubnubPubKey, subKey: AppConstants.pubnubSubKey, comChannel: (PFUser.currentUser()?.username)!)
        AppConstants.requestHandler!.addHandler(self)
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.tabBarController?.tabBar.hidden = false
    }
    
    func client(client: PubNub!, didReceiveMessage message: PNMessageResult!) {

        
        print("request notification!")
        
        /*
        if let curController = self.selectedViewController {
            if curController is TicketTableViewController
        }
        */
        
        // RequestTaken: someone just took your request
        // RequestSolved: someone just solved your request

        if let requestID = message.data.message["requestID"] as? String, requestType = message.data.message["requestType"] as? String {
            print(message.data.message)
//            print(String(format: "ID: %@ Type: %@", requestID, requestType))
            if requestType == "RequestTaken" {
                alertedTicketId = requestID
                print("moving ticket to taken")
//                AsyncTicketManager.sharedInstance.moveTicketToTakenById(requestID)
                TicketHandler.getTicketByID(requestID, completion: self.handleTicketTaken)
//                self.handleTicketTaken()
            } else if requestType == "RequestSolved" {
                AsyncTicketManager.sharedInstance.moveTicketToSolvedById(requestID)
                
            } else if requestType == "RequestReleased" {
                // TODO: Handle ticket being released
            } else if requestType == "RequestAdded" {
                print("Received notice to add ticket")
                if AsyncTicketManager.sharedInstance.getTicketByID(requestID) == nil {
                    TicketHandler.getTicketByID(requestID, completion: self.handleTicketAdded)
                } else {
                    print("Could not find added ticket")
                }
            } else if requestType == "RequestDeleted" {
                AsyncTicketManager.sharedInstance.deleteTicketByID(requestID)
            } else {
                print(String(format:"Unhandled request type: %s", requestType))
            }
        } else {
            print("bad message")
            print(message.data.message)
        }
    }
    
    func handleTicketAdded(ticket: PFObject?, error: NSError?) -> Void {
        if ticket != nil {
            print("Adding new ticket")
            let type = ticket!["taken"] as! Int
            AsyncTicketManager.sharedInstance.addTicket(ticket!, type: type)
        } else if (error != nil) {
            print("Could not add ticket")
            print(error)
        } else {
            print("Failed to add ticket with no error")
        }
    }
    
    func handleTicketTaken(ticket: PFObject?, error: NSError?) -> Void {
        
        if ticket != nil {
            print("ticket has been taken")
            AsyncTicketManager.sharedInstance.moveTicketToTaken(ticket!)
            incrementRequestBadge()
            self.presentYesNoAlert("Someone is here to help!", message: "Go to your ticket?", completion: self.goToTicket)
        } else if (error != nil) {
            print("Could not take ticket")
            print(error)
        } else {
            print("Failed to take ticket with no error")
        }
        
    }
    
    func handleTicketSolved() {
        self.presentYesNoAlert("Request Solved!", message: "Go check your solution!", completion: self.goToTicket)
    }
    
    func handleTicketReleased() {
        self.presentAlert("Your helper canceled", message: "A new helper will be on the way soon!", completion: nil)
    }
    
    func goToTicket(_: UIAlertAction) -> Void {
        if alertedTicket == nil {
            print("Could not redirect to ticket")
        } else {
            let storyboard = UIStoryboard(name: "message", bundle: nil)
            let controller = storyboard.instantiateViewControllerWithIdentifier("textTable") as! MessageViewController
            controller.ticket = alertedTicket
            AppConstants.ticketNavController?.pushViewController(controller, animated: true)
            self.tabBar.items![AppConstants.ticketsTabIndex].badgeValue = nil
            self.selectedIndex = AppConstants.ticketsTabIndex
        }
    }
    
    func incrementRequestBadge() {
        if self.tabBar.selectedItem != self.tabBar.items![AppConstants.ticketsTabIndex] {

            if let badgeValue = (self.tabBar.items![AppConstants.ticketsTabIndex]).badgeValue, let badgeInt = Int(badgeValue) {
                (self.tabBar.items![AppConstants.ticketsTabIndex]).badgeValue = (badgeInt + 1).description
            } else {
                (self.tabBar.items![AppConstants.ticketsTabIndex]).badgeValue = "1"
            }
        } /*else {
            if let controller = self.viewControllers?[AppConstants.ticketsTabIndex] as? UINavigationController {
                print("refresh ticekts now")
                if let ticketController = controller.viewControllers[0] as? TicketTableViewController {
                    ticketController.fetchTickets()
                } else {
                    print(controller.viewControllers)
                }
            } else {
                print(self.viewControllers)
                print("could not find ticket view controller")
            }
        }*/
    }
    
    override func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        if self.tabBar.selectedItem == self.tabBar.items![AppConstants.ticketsTabIndex] {
            self.tabBar.items![AppConstants.ticketsTabIndex].badgeValue = nil
        }
    }
    
}