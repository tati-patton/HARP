//
//  ContentView.swift
//  HARP
//
//  Created by user247259 on 11/11/23.
//

import SwiftUI
import UIKit
import HealthKit
import Foundation
import Combine

class DataModel: ObservableObject {
    @Published var allRetrievedData: [[String: String]] = []
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            //.environmentObject(Input())
            //.environmentObject(Calculate())
    }
}

enum YesNoOption: Int, CaseIterable {
    case yes = 1
    case no = 0
    
    var stringValue: String {
        switch self {
        case .yes: return "Yes"
        case .no: return "No"
        }
    }
}

extension YesNoOption: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self = YesNoOption(rawValue: value.lowercased() == "yes" ? 1 : 0) ?? .no
    }
}

let YesNoMapping: [String: Int] = ["Yes": 1, "No": 0]


/// Required user input: year of birth, height, weight, history of heart disease for the user and immediate family, smoking, birth control use, and primary diet (selection from a list of standardized options)
class UserData: ObservableObject {
    static let shared = UserData()
    
    @AppStorage("BirthYear") var birthYear: Int?
    @AppStorage("Height") var height: Double?
    @AppStorage("Weight") var weight: Double?
    @AppStorage("Contraception") var contraception: Int?
    @AppStorage("HeartDiseaseHistory") var heartDiseaseHistory: Int?
    @AppStorage("HeartDiseaseFamilial") var heartDiseaseFamilial: Int?
    @AppStorage("DiabetesHistory") var diabetesHistory: Int?
    @AppStorage("DiabetesFamilial") var diabetesFamilial: Int?
    @AppStorage("Smoking") var smoking: Int?
    @AppStorage("PrimaryDiet") var primaryDiet: Int = 0
    
    private init() {
    }
    let dietOptions: [String: Int] = [
        "Health-conscious": 0,
        "Vegan": 1,
        "Vegetarian": 2,
        "Balanced": 3,
        "Starchy": 4,
        "Meat-based": 5,
        "Fast-food": 6
    ]
}

struct MainView: View {
    @State private var storedResponses: [String] = UserDefaults.standard.stringArray(forKey: "StoredResponses") ?? []
    @State private var isEditing: Bool = false
    @EnvironmentObject var api: API
    //@StateObject var api
    @StateObject private var dataModel = DataModel()
    
    let formatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .medium
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()
    
    /// Create an instance of the health store. Use the health store to request authorization to access
    /// HealthKit records and to query for the records.
    let healthStore = HKHealthStore()
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.white, .white]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
                .onAppear() {
                    retrieveData()
                }
            VStack {
                Image(systemName: "heart.fill")
                    .imageScale(.large)
                    .foregroundStyle(.red)
                    .padding(.top, 15)
                    .padding(.bottom, 5)
                Text("Heart Attack Risk Predictor")
                    .font(.system(size:25, weight: .medium, design: .rounded))
                    .foregroundColor(.indigo)
                Spacer(minLength: 20)
                
                TabView {
                    InputView ()
                        .tabItem {
                            Label("Input Data", systemImage: "square.and.pencil")
                        }
                        .environmentObject(api)
                        .environmentObject(dataModel)
                    
                    CalculateView()
                        .tabItem {
                            Label("Calculate", systemImage: "heart")
                        }
                        .environmentObject(api)
                        .environmentObject(dataModel)
                } // tabView
                //.environmentObject(dataModel)
                //.environmentObject(api)
            }
        }
    } // body
    
    func retrieveData() {
        api.requestAuthorizationIfNeeded()
        // Clear existing data
        dataModel.allRetrievedData.removeAll()
        
        // Use HKSampleQuery to query the HealthKit store for samples by type.
        for section in Section.allCases {
            for sampleType in section.types {
                api.queryAndDisplayData(for: sampleType, section: section) {identifier, data in
                    DispatchQueue.main.async {
                        let newData = ["identifier": identifier, "data": data]
                        dataModel.allRetrievedData.append(newData)
                    }
                }
            }
        } // for
    }
}


#Preview {
    MainView()
}
