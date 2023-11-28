//
//  DataElements.swift
//  HARP
//
//  Created by user247259 on 11/12/23.
//

import Foundation
import HealthKit
import HealthKitUI
import SwiftUI

/// An enumeration that defines two categories of data types: Health Records and Fitness Data.
/// Health Records enumerates the clinical records the app would like to access and Fitness Data contains the
/// fitness data types.
let dayRange = 7 /// Number of days, for which to include symptoms and calculate average activity, body measurements, and vitals

enum Section: CaseIterable {
    case fitnessData
    case menstrualFlow
    case bodyMeasurements
    case symptoms
    
    var displayName: String {
        switch self {
        case .fitnessData:
            return "Fitness Data"
        case .menstrualFlow:
            return "Menstrual Tracking Data"
        case .symptoms:
            return "Symptoms"
        case .bodyMeasurements:
            return "Body Measurements"
        }
    }

    var types: [HKSampleType] {
        switch self {
        case .fitnessData:
            return [
                HKObjectType.quantityType(forIdentifier: .stepCount)!,
                HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
            ]
            
        case .menstrualFlow:
            return [
                HKObjectType.categoryType(forIdentifier: .irregularMenstrualCycles)!,
                HKObjectType.categoryType(forIdentifier: .infrequentMenstrualCycles)!,
                HKObjectType.categoryType(forIdentifier: .prolongedMenstrualPeriods)!,
                HKObjectType.categoryType(forIdentifier: .intermenstrualBleeding)!,
                HKObjectType.categoryType(forIdentifier: .persistentIntermenstrualBleeding)!,
                HKObjectType.categoryType(forIdentifier: .contraceptive)!
            ]
            
        case .symptoms:
            return [
                HKObjectType.categoryType(forIdentifier: .heartburn)!,
                HKObjectType.categoryType(forIdentifier: .nausea)!,
                HKObjectType.categoryType(forIdentifier: .dizziness)!,
                HKObjectType.categoryType(forIdentifier: .shortnessOfBreath)!,
                HKObjectType.categoryType(forIdentifier: .chestTightnessOrPain)!,
                HKObjectType.categoryType(forIdentifier: .vomiting)!,
                HKObjectType.categoryType(forIdentifier: .fainting)!,
                HKObjectType.categoryType(forIdentifier: .fatigue)!,
                HKObjectType.categoryType(forIdentifier: .nightSweats)!,
                HKObjectType.categoryType(forIdentifier: .abdominalCramps)!,
                HKObjectType.categoryType(forIdentifier: .irregularHeartRhythmEvent)!,
                HKObjectType.categoryType(forIdentifier: .highHeartRateEvent)!,
                HKObjectType.categoryType(forIdentifier: .lowHeartRateEvent)!,
                HKObjectType.categoryType(forIdentifier: .rapidPoundingOrFlutteringHeartbeat)!
            ]
            
        case .bodyMeasurements:
            return [
                HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
                HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
                HKObjectType.quantityType(forIdentifier: .heartRate)!,
                HKObjectType.quantityType(forIdentifier: .height)!,
                HKObjectType.quantityType(forIdentifier: .bodyMass)!
            ]
        }
    }
}

enum HKCategoryValueContraceptive: Int {
    case unspecified = 1
    case implant = 2
    case injection = 3
    case intrauterineDevice = 4
    case intravaginalRing = 5
    case oral = 6
    case patch = 7

    var description: String {
        switch self {
        case .unspecified: return "Unspecified"
        case .implant: return "Contraceptive Implant"
        case .injection: return "Injectable Contraceptive"
        case .intrauterineDevice: return "Intrauterine Device (IUD)"
        case .intravaginalRing: return "Contraceptive Intravaginal Ring"
        case .oral: return "Oral Contraceptive"
        case .patch: return "Contraceptive Patch"
        }
    }
}

class API: ObservableObject{
    @Published var retrievedData: [(identifier: String, data: String)] = []
    @Published var dataDict: [String:Double] = [:]
    //@EnvironmentObject var api: API
    var samples: [HKSample] = []
    var sampleTypes: Set<HKSampleType> {
        return Set(Section.fitnessData.types + Section.menstrualFlow.types + Section.symptoms.types + Section.bodyMeasurements.types)
    }
    
    /// Create an instance of the health store. Use the health store to request authorization to access
    /// HealthKit records and to query for the records.
    let healthStore = HKHealthStore()
    
    /// Before accessing clinical records and other health data from HealthKit, the app must ask the user for
    /// authorization. The health store's getRequestStatusForAuthorization method allows the app to check
    /// if user has already granted authorization. If the user hasn't granted authorization, the app
    /// requests authorization from the person using the app.
    @objc
    func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        healthStore.getRequestStatusForAuthorization(toShare: Set(), read: sampleTypes) { (status, error) in
            if status == .unnecessary {
                DispatchQueue.main.async {
                    let message = "Authorization status has been determined, no need to request authorization at this time"
                    //self.present(message: message, titled: "Already Requested")
                    print(message)
                    completion(true)
                }
            } else {
                self.requestAuthorization(completion: completion)
            }
            print(error ?? " ")
        }
    }
    
    /// The health store's requestAuthorization method presents a permissions sheet to the user, allowing the user to
    /// choose what data they allow the app to access.
    @objc
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        healthStore.requestAuthorization(toShare: nil, read: sampleTypes) { (success, error) in
            guard success else {
                DispatchQueue.main.async {
                    //self.handleError(error)
                    print("Error occurred \(String(describing: error))")
                    completion(false)
                }
                return
            }
            completion(true)
        }
    }
    
    /// Query and display data for a specific HKSampleType
    func queryAndDisplayData(for sampleType: HKSampleType, section: Section, completion: @escaping (String, String) -> Void) {
        let sortDescriptor = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        var limit = 1
        var predicate = HKQuery.predicateForSamples(withStart: nil, end: nil, options: [])
        if section == .bodyMeasurements || section == .fitnessData || section == .symptoms {
            let endDate = Date()
            var startDate = Calendar.current.date(byAdding: DateComponents(day: -dayRange), to: endDate)!
            startDate = Calendar.current.startOfDay(for: startDate)
            //let stepSampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: sampleType.identifier))
            predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            if section == .bodyMeasurements || section == .fitnessData {
                limit = 0
            }
        }
        print("Querying for sample type: \(sampleType.identifier)")
        // Create a query for the specified sample type
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: limit, sortDescriptors: sortDescriptor)
        { (_, samples_found, error) in
            guard let samples = samples_found else {
                print("Failed to retrieve samples with error: \(String(describing: error))")
                return
            }
            // Process and display the retrieved samples
            self.processAndDisplaySamples(samples, section: section, for: sampleType, completion: completion)
        }
        healthStore.execute(query)
    }
    
    /// Process and display the retrieved samples
    func processAndDisplaySamples(_ samples: [HKSample], section: Section, for sampleType: HKSampleType, completion: @escaping (String, String) -> Void) {
        var data: [(identifier: String, data: String)] = []
        var identifier = ""
        var sampleInfo = ""
        var dailyAVG:Double = 0
        var total: [String:Int] = [:]
        var unit: HKUnit? = nil
        var sampleData = (identifier: identifier, data: sampleInfo)
        for sample in samples {
            if let quantitySample = sample as? HKQuantitySample {
                let quantity = quantitySample.quantity
                identifier = sampleType.identifier.replacingOccurrences(of: "HKQuantityTypeIdentifier", with: "")
                total[identifier] =  (total[identifier] ?? 0) + 1
                
                if section == .bodyMeasurements || section == .fitnessData {
                    switch identifier {
                    case "StepCount":
                        unit = HKUnit.count()
                    case "DistanceWalkingRunning":
                        unit = HKUnit.mile()
                    case "BloodPressureSystolic":
                        unit = HKUnit.millimeterOfMercury()
                    case "BloodPressureDiastolic":
                        unit = HKUnit.millimeterOfMercury()
                    case "HeartRate":
                        unit = HKUnit.count().unitDivided(by: HKUnit.minute())
                    case "BodyMass":
                        unit = HKUnit.pound()
                    case "Height":
                        unit = HKUnit.foot()
                    default:
                        unit = HKUnit.count()
                    }
                    // add values to dailyAVG
                    dailyAVG += quantitySample.quantity.doubleValue(for: unit!)
                } else {
                    sampleInfo = "\(quantity)"
                    sampleData = (identifier: identifier, data: sampleInfo)
                    data.append(sampleData)
                    completion(identifier, sampleInfo)
                    dataDict[identifier] = Double(sampleInfo)
                    print(data)
                }
            }
            // Handle other types of samples
            if let catSample = sample as? HKCategorySample {
                let value = catSample.value
                let valueDesc = value >= 0 ?"Present": "None"
                identifier = sampleType.identifier.replacingOccurrences(of: "HKCategoryTypeIdentifier", with: "")
                sampleInfo = "\(valueDesc)"
                sampleData = (identifier: identifier, data: sampleInfo)
                data.append(sampleData)
                completion(identifier, sampleInfo)
                dataDict[identifier] = 1.0
                if identifier == "Contraceptive" {
                    if sampleInfo == "Present" {
                    UserData.shared.contraception = 1
                    } else {
                        UserData.shared.contraception = 0
                    }
                }
                print(data)
            }
            // Handle clinical types of samples
            if let clinicalSample = sample as? HKClinicalRecord {
                print("Clinical data found")
                guard let fhirRecord = clinicalSample.fhirResource else {
                    print("No FHIR record found!")
                    return
                }
                do {
                    let jsonDictionary = try JSONSerialization.jsonObject(with: fhirRecord.data, options: [])
                    print(jsonDictionary)
                    // Do something with the JSON data here.
                }
                catch let error {
                    print("*** An error occurred while parsing the FHIR data: \(error.localizedDescription) ***")
                    // Handle JSON parse errors here.
                }
            }
        }
        // Return agregate samples
        if identifier != "" && (section == .bodyMeasurements || section == .fitnessData) {
            let days = total[identifier] ?? 0 > 7 ? dayRange : total[identifier] ?? 0
            dailyAVG = total[identifier] ?? 0 > 0 ? dailyAVG / Double(days) : dailyAVG
            sampleInfo = String(format: "%.2f", dailyAVG)
            sampleData = (identifier: identifier, data: sampleInfo)
            data.append(sampleData)
            dataDict[identifier] = Double(sampleInfo)
            if let unit_st = unit {
                completion("\(identifier) (\(unit_st))", sampleInfo)
            } else {
                completion(identifier, sampleInfo)
            }
            if identifier == "Height" {
                UserData.shared.height = round(100 * Double(sampleInfo)!) / 100
            }
            if identifier == "BodyMass" {
                UserData.shared.weight = round(100 * Double(sampleInfo)!) / 100
            }
            print(data, total[identifier] ?? 0)
        }
    }
    @objc
    func getRetrievedData () -> [String:Double] {
        return dataDict
    }
}
