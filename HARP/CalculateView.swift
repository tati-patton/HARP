//
//  CalculateView.swift
//  HARP
//
//  Created by user247259 on 11/16/23.
//

import SwiftUI
import UIKit
import HealthKit
import CoreML
import Foundation

struct CalculateView: View {
    @EnvironmentObject var dataModel: DataModel
    @EnvironmentObject var api: API
    @State private var showAlert = false
    @State private var result: Double = 0.0
    @State private var recommendation: String = ""
    var body: some View {
        VStack {
            // Iterate over each set of retrieved data
            if dataModel.allRetrievedData.isEmpty {
                Text("No data retrieved from Apple Health. \nPlease check your data sharing permissions.")
                    .padding(15)
            } else {
                List {
                    SwiftUI.Section (header: Text("Retrieved factors")) {
                        ForEach(dataModel.allRetrievedData, id: \.self) { retrievedData in
                            // Display the retrieved data
                            HStack {
                                Text("\(retrievedData["identifier"] ?? "")")
                                Spacer()
                                Text("\(retrievedData["data"] ?? "")")
                                //Text("\(api.dataDict[(retrievedData["identifier"] ?? "")] ?? 0)")
                            }
                        }
                    }
                }
            }
            
            Button(action: {
                // Predict risk and output results
                if UserData.shared.birthYear ?? 0 > 0 && UserData.shared.height ?? 0 > 0 && UserData.shared.weight ?? 0 > 0 && !dataModel.allRetrievedData.isEmpty {
                    // Calculate age
                    let currentYear = Calendar.current.component(.year, from: Date())
                    let age = Double(currentYear - (UserData.shared.birthYear ?? 0))
                    
                    // Calculate BMI
                    let BMI = 703 * (UserData.shared.weight ?? 0) / pow(((UserData.shared.height ?? 0) * 12), 2)
                                        
                    // Predict risk
                    let model = RandomForest2()
                    guard let risk = try? model.prediction(Age: age, BMI: BMI, Contraceptive: Double(UserData.shared.contraception ?? 0), HeartDiseaseHistory: Double(UserData.shared.heartDiseaseHistory ?? 0), HeartDiseaseFamilial: Double(UserData.shared.heartDiseaseFamilial ?? 0), DiabetesHistory: Double(UserData.shared.diabetesHistory ?? 0), DiabetesFamilial: Double(UserData.shared.diabetesFamilial ?? 0), Smoking: Double(UserData.shared.smoking ?? 0), PrimaryDiet: Double(UserData.shared.primaryDiet ), StepCount: api.dataDict["StepCount"] ?? 0, DistanceWalkingRunning: api.dataDict["DistanceWalkingRunning"] ?? 0, irregularMenstrualCycles: api.dataDict["IrregularMenstrualCycles"] ?? 0, infrequentMenstrualCycles: api.dataDict["InfrequentMenstrualCycles"] ?? 0, prolongedMenstrualPeriods: api.dataDict["ProlongedMenstrualPeriods"] ?? 0, intermenstrualBleeding: api.dataDict["IntermenstrualBleeding"] ?? 0, persistentIntermenstrualBleeding: api.dataDict["PersistentIntermenstrualBleeding"] ?? 0, heartburn: api.dataDict["Heartburn"] ?? 0, nausea: api.dataDict["Nausea"] ?? 0, dizziness: api.dataDict["Dizziness"] ?? 0, shortnessOfBreath: api.dataDict["ShortnessOfBreath"] ?? 0, chestTightnessOrPain: api.dataDict["ChestTightnessOrPain"] ?? 0, vomiting: api.dataDict["Vomiting"] ?? 0, fainting: api.dataDict["Fainting"] ?? 0, fatigue: api.dataDict["Fatigue"] ?? 0, nightSweats: api.dataDict["NightSweats"] ?? 0, abdominalCramps: api.dataDict["AbdominalCramps"] ?? 0, irregularHeartRhythmEvent: api.dataDict["IrregularHeartRhythmEvent"] ?? 0, highHeartRateEvent: api.dataDict["HighHeartRateEvent"] ?? 0, lowHeartRateEvent: api.dataDict["LowHeartRateEvent"] ?? 0, rapidPoundingOrFlutteringHeartbeat: api.dataDict["RapidPoundingOrFlutteringHeartbeat"] ?? 0, bloodPressureSystolic: api.dataDict["BloodPressureSystolic"] ?? 0, bloodPressureDiastolic: api.dataDict["BloodPressureDiastolic"] ?? 0, heartRate: api.dataDict["HeartRate"] ?? 0) else {
                        fatalError("Unexpected runtime error.")
                    }
                    result = risk.HeartAttack * 100
                    switch result{
                    case 0.01...4.99:
                        recommendation = "\nYou’re at low risk for a serious cardiovascular event. Keep moving in a positive direction!\nSchedule an appointment with your healthcare professional to make a plan for a long, heart-healthy life and discuss factors that can increase your risk of heart disease or stroke.\n\nA great place to start is by following a heart-healthy lifestyle:\n- Maintain a heart-healthy diet;\n- Be active;\n- Keep your weight in check."
                    case 5.00...7.49:
                        recommendation = "\nYou’re at borderline risk for a serious cardiovascular event.\nYou’ve got some work to do, but you can handle this!\nIt is very important that you make an appointment with your health care professional right now. Based on your risk level, they will probably want to discuss a statin medication to lower your LDL-cholesterol and talk about factors that can increase your risk of heart disease or stroke.\n\nA great place to start is by following a heart-healthy lifestyle:\n- Maintain a heart-healthy diet;\n- Be active;\n- Keep your weight in check."
                    case 7.50...19.99:
                        recommendation = "\nYou’re at intermediate risk for a serious cardiovascular event.\nYou’ve got some work to do, but you can handle this!\nSchedule an appointment with your healthcare professional to make a plan for a long, heart-healthy life and discuss factors that can increase your risk of heart disease or stroke. Your health care professional will probably want to check back with you in 1-3 months to see the progress you're making.\n\nFollow the ‘ABCS’ of prevention that can reduce your risk:\n- Asprin Therapy;\n- Blood pressure management;\n- Cholesterol Management;\n- Smoking cessation."
                    case 20.00...49.99:
                        recommendation = "\nYou’re at high risk for a serious cardiovascular event.\nYou’ve got some work to do, but you can handle this!\nIt is very important that you make an appointment with your healthcare professional right now. Based on your risk level, they will probably want to discuss a statin medication to lower your LDL-cholesterol.\n\nFollow the ‘ABCS’ of prevention that can reduce your risk:\n- Asprin Therapy;\n- Blood pressure management;\n- Cholesterol Management;\n- Smoking cessation."
                    case 50.0...100.0:
                        recommendation = "\nYou’re at very high risk for a serious cardiovascular event.\nCall 911 immediately if you are experiencing the following symptoms:\n- Chest pain or discomfort;\n- Shortness of breath;\n- Pain or discomfort in the jaw, neck, back, arm, or shoulder;\n- Indigestion, heartburn, nausea or vomiting;\n- Fluttering feelings in the chest (palpitations);\n- Swelling of the feet, ankles, legs, or abdomen;\n- Feeling dizzy, light-headed, or unusually tired."
                    default:
                        recommendation = "No recommendation could be provided."
                    }
                }
                showAlert = true
            }, label: {
                Text("Calculate Risk")
                    .frame(width: 140,height: 45, alignment: .center)
                    .background(Color.indigo)
                //.overlay(RoundedRectangle(cornerRadius: 5.0)
                //.stroke(Color.gray))
                //.shadow(color: .white, radius:5)
                    .foregroundColor(.white)
                    .font(.system(size:17, weight: .bold, design: .default))
                    .cornerRadius(8.0)
            })
            .alert(isPresented: $showAlert) {
                if result > 0 {
                    let formattedResult = String(format: "%.2f", result)
                    return Alert(
                        title: Text("\(formattedResult)%"),
                        message: Text("This is your predicted heart attack risk based on current data.\n")
                        + Text("\(recommendation)")
                    )
                } else {
                    return Alert(
                        title: Text("Insufficient Data"),
                        message: Text("Insufficient data for calculating the risk."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .padding(35)
        } // VStack
        //} // ZStack
    }
}
