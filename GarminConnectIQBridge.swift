
import Foundation
import CompanionSdk

class GarminConnectIQBridge: NSObject, ConnectIQDeviceEventDelegate {
    static let shared = GarminConnectIQBridge()
    
    private var device: IQDevice?
    private var glucoseApp: IQApp?
    private var connectIQ: ConnectIQ?
    
    override init() {
        super.init()
        initializeConnectIQ()
    }
    
    // MARK: - Initialize Connect IQ
    func initializeConnectIQ() {
        do {
            connectIQ = try ConnectIQ.sharedInstance()
            connectIQ?.registerDeviceEventDelegate(self)
            print("✅ Garmin Connect IQ initialized")
        } catch {
            print("❌ Failed to initialize Connect IQ: \(error)")
        }
    }
    
    // MARK: - Send Glucose to Watch
    func sendGlucoseToWatch(mgdl: Int, trend: String) {
        guard let connectIQ = connectIQ,
              let device = device,
              let glucoseApp = glucoseApp else {
            print("❌ Device or app not connected")
            return
        }
        
        let payload: [String: Any] = [
            "mgdl": mgdl,
            "trend": trend
        ]
        
        connectIQ.sendMessage(to: device,
                             forApp: glucoseApp,
                             withPayload: payload) { (result) in
            switch result.statusCode {
            case .success:
                print("✅ Glucose sent: \(mgdl) mg/dL (\(trend))")
            case .deviceNotPaired:
                print("❌ Device not paired")
            case .appNotInstalled:
                print("❌ Glucose app not installed on watch")
            case .invalidPayload:
                print("❌ Invalid payload format")
            case .unknown:
                print("❌ Unknown error sending message")
            default:
                print("❌ Error: \(result.statusCode)")
            }
        }
    }
    
    // MARK: - Device Event Delegate Methods
    func deviceDidConnect(_ device: IQDevice!) {
        print("✅ Watch connected: \(device.friendlyName ?? "Unknown")")
        self.device = device
        
        guard let connectIQ = connectIQ else { return }
        
        connectIQ.getConnectIQApps(forDevice: device) { (apps, error) in
            if let apps = apps as? [IQApp] {
                self.glucoseApp = apps.first { $0.displayName?.contains("Glucose") ?? false }
                if self.glucoseApp != nil {
                    print("✅ Glucose app found on watch")
                } else {
                    print("⚠️ Glucose app not found on watch")
                }
            }
        }
    }
    
    func deviceDidDisconnect(_ device: IQDevice!) {
        print("⚠️ Watch disconnected")
        self.device = nil
        self.glucoseApp = nil
    }
    
    func deviceDidFailToConnect(_ device: IQDevice!, withError error: Error!) {
        print("❌ Failed to connect: \(error?.localizedDescription ?? "Unknown")")
    }
}