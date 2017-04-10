//
//  AppDelegate.swift
//  BTMonitor
//
//  Created by Paul Wilkinson on 9/4/17.
//  Copyright © 2017 Paul Wilkinson. All rights reserved.
//

import UIKit
import CoreData
import CoreBluetooth
import UserNotifications
import BRYXBanner

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    var btManager: BTManager!
    let center = UNUserNotificationCenter.current()
    
    private var connection: Connection?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        if let centraloption = launchOptions?[UIApplicationLaunchOptionsKey.bluetoothCentrals] {
            self.btManager = BTManager.sharedManager
            self.sendLocalNotification(title: "Bluetooth restored", body: "Restoring \(centraloption)")
        } else {
            self.sendLocalNotification(title: "Standard launch", body: "Standard launch")
        }
        
        if self.btManager == nil {
             self.btManager = BTManager.sharedManager
        }
        
        
        
        let options: UNAuthorizationOptions = [.alert, .sound];
        center.requestAuthorization(options: options) {
            (granted, error) in
            if !granted {
                print("Something went wrong")
            }
        }
        
        let nc = NotificationCenter.default
        
        nc.addObserver(forName: BTManager.connectionNotification, object: nil, queue: OperationQueue.main) { (notification) in
            if let state = notification.userInfo?["STATE"] as? Bool {
                
                if state {
                    let newConnection = Connection(context: self.persistentContainer.viewContext)
                    newConnection.connectTime = Date() as NSDate
                    self.connection = newConnection
                    newConnection.bgTime = UIApplication.shared.backgroundTimeRemaining
                } else {
                    if let currentConnection = self.connection {
                        currentConnection.disconnectTime = Date() as NSDate
                        currentConnection.bgTime = UIApplication.shared.backgroundTimeRemaining
                    } else {
                        let newConnection =  Connection(context: self.persistentContainer.viewContext)
                        newConnection.disconnectTime = Date() as NSDate
                        newConnection.bgTime = UIApplication.shared.backgroundTimeRemaining
                    }
                }
                
                self.saveContext()
                
                
                
                self.sendLocalNotification(title: "Bluetooth connection change", body: state ? "Peripheral is now connected":"Peripheral is now disconnected")
                
                
            }
            
        }
        
        return true
    }
    
    func sendLocalNotification(title: String, body: String) {
        if UIApplication.shared.applicationState  == .background {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = UNNotificationSound.default()
            let identifier = title+body
            let request = UNNotificationRequest(identifier: identifier,
                                                content: content, trigger: nil)
            center.add(request, withCompletionHandler: { (error) in
                if let error = error {
                    print(error)
                }
            }) } else {
            
            if topWindow() != nil {
                self.showBanner(title: title, body: body, backgroundColor: .blue)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                    self.showBanner(title: title, body:body,backgroundColor: .blue)
                })
            }
            
        }
    }
    
    func topWindow() -> UIWindow? {
        for window in UIApplication.shared.windows.reversed() {
            if window.windowLevel == UIWindowLevelNormal && !window.isHidden && window.frame != CGRect.zero { return window }
        }
        return nil
    }
    
    func showBanner(title: String, body:String, backgroundColor: UIColor) {
        let banner = Banner(title: title, subtitle: body, image: nil, backgroundColor: backgroundColor, didTapBlock: nil)
        
        banner.dismissesOnTap = true
        banner.show(duration: 3.0)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "BTMonitor")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}
