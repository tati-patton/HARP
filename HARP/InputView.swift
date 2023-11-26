//
//  InputView.swift
//  HARP
//
//  Created by user247259 on 11/16/23.
//

import SwiftUI

//struct InputView<Content: View>: View {
//    let content: () -> Content
//
//    init(@ViewBuilder content: @escaping () -> Content) {
//        self.content = content
//    }
//
//    var body: some View {
//        content()
//    }
//}

import SwiftUI
import UIKit
import HealthKit


struct InputView: View {
    @ObservedObject var userData = UserData.shared
    @EnvironmentObject var api: API
    var body: some View {
        //@EnvironmentObject var dataModel: DataModel
        
        @AppStorage("BirthYear") var birthYear: Int = UserData.shared.birthYear ?? 0
        @AppStorage("Height") var height: Double = UserData.shared.height ?? 0
        @AppStorage("Weight") var weight: Double = UserData.shared.weight ?? 0
        @AppStorage("Contraception") var contraception: Int = UserData.shared.contraception ?? 0
        @AppStorage("HeartDiseaseHistory") var heartDiseaseHistory: Int = UserData.shared.heartDiseaseHistory ?? 0
        @AppStorage("HeartDiseaseFamilial") var heartDiseaseFamilial: Int = UserData.shared.heartDiseaseFamilial ?? 0
        @AppStorage("DiabetesHistory") var diabetesHistory: Int = UserData.shared.diabetesHistory ?? 0
        @AppStorage("DiabetesFamilial") var diabetesFamilial: Int = UserData.shared.diabetesFamilial ?? 0
        @AppStorage("Smoking") var smoking: Int = UserData.shared.smoking ?? 0
        @AppStorage("PrimaryDiet") var primaryDiet: Int = UserData.shared.primaryDiet
                
        VStack {
            Spacer()
            if UserData.shared.birthYear ?? 0 > 0 {
                Text("Please review and update your information:")
            } else {
                Text("Please populate your information:")
            }
            /// Collect user input
            Form {
                SwiftUI.Section(header: Text("User Input")) {
                    Picker("Birth Year", selection: $birthYear) {
                        ForEach(Array(1900..<2030), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .onChange(of: birthYear) { newValue in
                        UserData.shared.birthYear = newValue
                    }
                    //.pickerStyle(WheelPickerStyle())
                    
                    Picker("Height, ft", selection: $height) {
                        ForEach(Array(stride(from: 3.0, through: 7.0, by: 0.05)), id: \.self) { height in
                            Text(String(format: "%.2f", height))
                                .tag(height)
                        }
                    }
                    .onChange(of: height) { newValue in
                        UserData.shared.height = newValue
                    }
                    
                    Picker("Weight, lbs", selection: $weight) {
                        ForEach(Array(stride(from: 30.0, through: 700.0, by: 1.0)), id: \.self) { weight in
                            Text(String(format: "%.1f", weight))
                                .tag(weight)
                        }
                    }
                    .onChange(of: weight) { newValue in
                        UserData.shared.weight = newValue
                    }
                    
                    Toggle("Do you use contraception?", isOn: Binding(
                        get: { userData.contraception == 1 },
                        set: { newValue in
                            userData.contraception = newValue ? 1 : 0
                        }
                    ))
                    
                    Toggle("Do you have a history of heart disease?", isOn: Binding(
                        get: { userData.heartDiseaseHistory == 1 },
                        set: { newValue in
                            userData.heartDiseaseHistory = newValue ? 1 : 0
                        }
                    ))
                    
                    Toggle("Does heart disease run in your family?", isOn: Binding(
                        get: { userData.heartDiseaseFamilial == 1 },
                        set: { newValue in
                            userData.heartDiseaseFamilial = newValue ? 1 : 0
                        }
                    ))
                    
                    Toggle("Do you have a history of diabetes?", isOn: Binding(
                        get: { userData.diabetesHistory == 1 },
                        set: { newValue in
                            userData.diabetesHistory = newValue ? 1 : 0
                        }
                    ))
                    
                    Toggle("Does diabetes run in your family?", isOn: Binding(
                        get: { userData.diabetesFamilial == 1 },
                        set: { newValue in
                            userData.diabetesFamilial = newValue ? 1 : 0
                        }
                    ))
                    
                    Toggle("Do you smoke?", isOn: Binding(
                        get: { userData.smoking == 1 },
                        set: { newValue in
                            userData.smoking = newValue ? 1 : 0
                        }
                    ))
                                        
                    Picker("Primary Diet", selection: $userData.primaryDiet) {
                        ForEach(userData.dietOptions.sorted(by: { $0.0 < $1.0 }), id: \.key) { key, value in
                            Text(key).tag(value)
                        }
                    }
                    .onChange(of: userData.primaryDiet) { newValue in
                    }
                }
            }
            
            .padding(5)
        } // VStack
    }
}
