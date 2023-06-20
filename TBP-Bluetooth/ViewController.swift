//
//  ViewController.swift
//  TBP-Bluetooth
//
//  Created by Cesar Rojas on 6/15/23.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    //Labels
    var redLabel: UILabel!
    var greenLabel: UILabel!
    var blueLabel: UILabel!
    
    //Sliders
    var redSlider: UISlider!
    var greenSlider: UISlider!
    var blueSlider: UISlider!

    //Properties
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    private var peripherals: [CBPeripheral] = []
    
    private var redChar: CBCharacteristic?
    private var greenChar: CBCharacteristic?
    private var blueChar: CBCharacteristic?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set labels
        redLabel = UILabel(frame: CGRect(x: 50, y: 350, width: 200, height: 30))
        redLabel.text = "Red"
        view.addSubview(redLabel)
        
        greenLabel = UILabel(frame: CGRect(x: 50, y: 400, width: 200, height: 30))
        greenLabel.text = "Green"
        view.addSubview(greenLabel)
        
        blueLabel = UILabel(frame: CGRect(x: 50, y: 450, width: 200, height: 30))
        blueLabel.text = "Blue"
        view.addSubview(blueLabel)
        
        //Set sliders
        redSlider = UISlider(frame: CGRect(x: 120, y: 350, width: 200, height: 30))
        redSlider.minimumValue = 0
        redSlider.maximumValue = 255
        redSlider.tintColor = .red
        redSlider.isEnabled = false
        redSlider.addTarget(self, action: #selector(redSliderChanged), for: .valueChanged)
        view.addSubview(redSlider)
        
        greenSlider = UISlider(frame: CGRect(x: 120, y: 400, width: 200, height: 30))
        greenSlider.minimumValue = 0
        greenSlider.maximumValue = 255
        greenSlider.tintColor = .green
        greenSlider.isEnabled = false
        greenSlider.addTarget(self, action: #selector(greenSliderChanged), for: .valueChanged)
        view.addSubview(greenSlider)
        
        blueSlider = UISlider(frame: CGRect(x: 120, y: 450, width: 200, height: 30))
        blueSlider.minimumValue = 0
        blueSlider.maximumValue = 255
        blueSlider.tintColor = .blue
        blueSlider.isEnabled = false
        blueSlider.addTarget(self, action: #selector(blueSliderChanged), for: .valueChanged)
        view.addSubview(blueSlider)
        
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    private func writeLEDValueToChar(withCharacteristics characteristic: CBCharacteristic, withValue value: Data) {
        
        //Check if it has the write property
        if characteristic.properties.contains(.writeWithoutResponse) && peripheral != nil {
            
            peripheral.writeValue(value, for: characteristic, type: .withoutResponse)
        }
    }
    
    @objc func redSliderChanged(_ sender: UISlider) {
        print("red:", redSlider.value)
        let slider:UInt8 = UInt8(redSlider.value)
        writeLEDValueToChar(withCharacteristics: redChar!, withValue: Data([slider]))
    }
    
    @objc func greenSliderChanged(_ sender: UISlider) {
        print("green:", greenSlider.value)
        let slider:UInt8 = UInt8(greenSlider.value)
        writeLEDValueToChar(withCharacteristics: greenChar!, withValue: Data([slider]))
    }
    @objc func blueSliderChanged(_ sender: UISlider) {
        print("blue:", blueSlider.value)
        let slider:UInt8 = UInt8(blueSlider.value)
        writeLEDValueToChar(withCharacteristics: blueChar!, withValue: Data([slider]))
    }
}

extension ViewController: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central State Update")
        if central.state != .poweredOn {
            print("Central is not Powered ON")
        } else {
            print("Central scanning for", ParticlePeripheral.particleLEDServiceUUID)
//            centralManager.scanForPeripherals(withServices: [ParticlePeripheral.particleLEDServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }

//    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
//
//        self.centralManager.stopScan()
//        self.peripheral = peripheral
//        self.peripheral.delegate = self
//        self.centralManager.connect(self.peripheral, options: nil)
//
//    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
            if !peripherals.contains(peripheral) {
                peripherals.append(peripheral)
                print("Discovered peripheral:", peripheral)
            }
        }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            print("Connected to your particle board")
            peripheral.discoverServices([ParticlePeripheral.particleLEDServiceUUID])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        if peripheral == self.peripheral {
            print("Disconnected")
            
            redSlider.isEnabled = false
            greenSlider.isEnabled = false
            blueSlider.isEnabled = false
            
            redSlider.value = 0
            greenSlider.value = 0
            blueSlider.value = 0
            
            self.peripheral = nil
            
            //Start scanning again
            print("Central scanning for", ParticlePeripheral.particleLEDServiceUUID)
            centralManager.scanForPeripherals(withServices: [ParticlePeripheral.particleLEDServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        }
    }
}

extension ViewController: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == ParticlePeripheral.particleLEDServiceUUID {
                    print("LED service found")
                    peripheral.discoverCharacteristics([ParticlePeripheral.redLEDCharacteristicUUID, ParticlePeripheral.greenLEDCharacteristicUUID, ParticlePeripheral.blueLEDCharacteristicUUID], for: service)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == ParticlePeripheral.redLEDCharacteristicUUID {
                    print("Red LED characteristics found")
                    redChar = characteristic
                    redSlider.isEnabled = true
                } else if characteristic.uuid == ParticlePeripheral.greenLEDCharacteristicUUID {
                    print("Green LED characteristics found")
                    greenChar = characteristic
                    greenSlider.isEnabled = true
                } else if characteristic.uuid == ParticlePeripheral.blueLEDCharacteristicUUID {
                    print("Blue LED characteristics found")
                    blueChar = characteristic
                    blueSlider.isEnabled = true
                }
            }
        }
    }
    
}
