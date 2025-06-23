//
//  NutritionView.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 5/8/24.
//

import SwiftUI
import GoogleGenerativeAI
import RiveRuntime
struct NutritionView: View {
    @State var buttonPressed = false
    @State var buttonPressed2 = false
    @StateObject var viewModel: ListViewModel
    @StateObject var viewModel2: ListViewModel
    @State  var expandedIndexes = Set<Int>()
    @State private var items: [Food] = []
    @State private var newItemName: String = ""
    @Binding  var persistenceManager: PersistenceManager
    @State var tempFood:Food?
    @State var number: Int = 0
    @State var quantity: String = ""
    @State var Calories: Int = 0
    @State var Sugar: Int = 0
    @State var Carbs: Int = 0
    @State var Protein: Int = 0

    @State var reload = true
    @State private var showScanner = false
    @State private var showBarcodeError = false
    @State private var barcodeErrorMessage = ""
    
    
    var body: some View {
        if buttonPressed {
                    NavigationView {
                        VStack {
                            HStack {
                                
                                VStack {
                                    
                                        if(buttonPressed2){
                                            Form {
                                                Section(header:  Text("Name").foregroundColor(.white) ) {
                                                    TextField("Food Name", text: $newItemName)
                                                        .listRowBackground(Color.gray)
                                                        .foregroundColor(.white)
                                                }
                                                .foregroundColor(.white)
                                                Section(header: Text("Calories")) {
                                                    TextField("Calories", text: Binding<String>(
                                                        get: { String(Calories) },
                                                        set: { if let newValue = Int($0) { Calories = newValue } }
                                                    ))
                                                    .keyboardType(.numberPad)
                                                    .listRowBackground(Color.gray)
                                                }
                                                .foregroundColor(.white)
                                                .bold()
                                                Section(header: Text("Sugars")) {
                                                    TextField("Sugars", text: Binding<String>(
                                                        get: { String(Sugar) },
                                                        set: { if let newValue = Int($0) { Sugar = newValue } }
                                                    ))
                                                    .keyboardType(.numberPad)
                                                    .listRowBackground(Color.gray)
                                                }
                                                .foregroundColor(.white)
                                                .bold()
                                                Section(header: Text("Carbs")) {
                                                    TextField("Carbs", text: Binding<String>(
                                                        get: { String(Carbs) },
                                                        set: { if let newValue = Int($0) { Carbs = newValue } }
                                                    ))
                                                    .keyboardType(.numberPad)
                                                    .listRowBackground(Color.gray)
                                                }
                                                .foregroundColor(.white)
                                                .bold()
                                                Section(header: Text("Protein")) {
                                                    TextField("Protein", text: Binding<String>(
                                                        get: { String(Protein) },
                                                        set: { if let newValue = Int($0) { Protein = newValue } }
                                                    ))
                                                    .keyboardType(.numberPad)
                                                    .listRowBackground(Color.gray)
                                                }
                                                .foregroundColor(.white)
                                                .bold()
                                            }
                                            .frame(width: 450,height: 500)
                                                .foregroundColor(.white)
                                                .bold()
                                                
                                        }
                                        else{
                                            Form {
                                            
                                            Section(header:  Text("Name").foregroundColor(.white) ) {
                                            TextField("Food Name", text: $newItemName)
                                                .listRowBackground(Color.gray)
                                                .foregroundColor(.white)
                                        }
                                        .foregroundColor(.white)
                                            Section(header: Text("Number")) {
                                                TextField("Number", text: Binding<String>(
                                                    get: { String(number) },
                                                    set: { if let newValue = Int($0) { number = newValue } }
                                                ))
                                                .keyboardType(.numberPad)
                                                .listRowBackground(Color.gray)
                                            }
                                            .foregroundColor(.white)
                                            .bold()
                                            Section(header: Text("Quantity or description").foregroundColor(.white)) {
                                                TextField("Quantity or description", text: $quantity)
                                                    .listRowBackground(Color.gray)
                                                    .foregroundColor(.white)
                                            }
                                            .foregroundColor(.white)
                                            .scrollContentBackground(.hidden)
                                        } .scrollContentBackground(.hidden)
                                                .frame(width: 450,height: 300)
                                            .foregroundColor(.white)
                                            .bold()
                                        
                                    }
                                }
                              
                            }
                            Spacer()
                            HStack{
                                Spacer()
                                Button{
                                    buttonPressed2 = true
                                }label: {
                                    Text("Custom").font(.title3).foregroundStyle(Color.white).background(RoundedRectangle(cornerRadius: 90).foregroundStyle(Color.accentColor).frame(width: 150, height: 50) ).padding(.bottom)
                                }
                                Spacer()
                                Button(action: {
                                    showScanner = true
                                }) {
                                    Image(systemName: "barcode.viewfinder").foregroundStyle(Color.white).frame(width: 40, height: 40)
                                }
                                Spacer(minLength: 70)
                                Button(action: {
                                    if buttonPressed2{
                                        tempFood = Food(Name: newItemName, Calories: Calories, Sugars: Sugar, Carbohydrates: Carbs, Protein: Protein)
                                        addItem()
                                        HealthManager.shared.calories += tempFood?.Calories ?? 0
                                        HealthManager.shared.sugars += tempFood?.Sugars ?? 0
                                        HealthManager.shared.protein += tempFood?.Protein ?? 0
                                        HealthManager.shared.carbs += tempFood?.Carbohydrates ?? 0
                                        newItemName = ""
                                        self.number = 0
                                        self.quantity = ""
                                        
                                      
                                        buttonPressed = false
                                    }else {
                                        
                                    
                                    Task {
                                        try await geminii()
                                    }
                                }
                                }) {
                                    Text("Add").font(.title3).foregroundStyle(Color.white).background(RoundedRectangle(cornerRadius: 90).foregroundStyle(Color.red).frame(width: 150, height: 50) ).padding(.bottom)
                                }
                                Spacer()
                            }
                            Spacer(minLength: 80)
                        }
                        
                        .padding()
                        .navigationTitle("Add Food")
                        .scrollContentBackground(.hidden)
                        .onAppear {
                            items = persistenceManager.loadItems()

                        }
                        .sheet(isPresented: $showScanner) {
                            BarcodeScannerView { code in
                                Task {
                                    await handleBarcode(code)
                                }
                                showScanner = false
                            }
                        }
                        .alert("Barcode Error", isPresented: $showBarcodeError) {
                            Button("OK", role: .cancel) {}
                        } message: {
                            Text(barcodeErrorMessage)
                        }
                    }
                }
        else{
            VStack{
                HStack{
                    Spacer().frame(width: 20)
                    if viewModel.items.isEmpty{
                        HStack{
                            Text("No food added yet!").font(.title).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).italic().fontDesign(.rounded)
                            if #available(iOS 18.0, *) {
                                Image(systemName: "arrow.right")
                                    .padding(.leading)
                                    .font(.title)
                                    .symbolEffect(.bounce.up.byLayer, options: .repeating)
                            } else {
                                Image(systemName: "arrow.right")
                                    .padding(.leading)
                                    .font(.title)
                            }
                            
                        }
                    }else{
                        Text("Today you had: ").font(.title).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).italic()
                    }
                    Spacer()
                    Button(action: {
                        buttonPressed = true
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.white)
                            .font(.title)
                            .frame(width: 50, height: 80)
                            
                            .clipShape(Circle())
                    }
                    Spacer().frame(width: 20)
                }
                ScrollView{
                  ForEach(viewModel.items) { item in
                      ExpandableBoxView(item: item, persistenceManager: self.persistenceManager)
                        .onTapGesture {
                            viewModel.toggleExpand(for: item)
                        }
                        .animation(.easeInOut, value: item.isExpanded)
                  }
                   
                }
                Spacer()
                
                
            }.onAppear{
               
                viewModel.items.removeAll()
                let temp = persistenceManager.loadItems()
                for i in  0..<persistenceManager.loadItems().count {
                    viewModel.items.append(ExcListItem(title: temp[i].Name, description: "This food with this portion has approx: \(temp[i].Calories) calories, \(temp[i].Protein)g of protein, \(temp[i].Carbohydrates) Carbs, \(temp[i].Sugars)g of sugars", totalCalories: 0, duration: 0, NumExcersises: 0))
                }
               
               
               
                
            }
            .alert("Barcode Error", isPresented: $showBarcodeError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(barcodeErrorMessage)
            }
        }
    }
  
  
    private func addItem() {
        guard let food = tempFood else { return }

        items.append(food)
        persistenceManager.saveItems(items: items)

        viewModel.items.append(
            ExcListItem(
                title: food.Name,
                description: "This food with this portion has approx: \(food.Calories) calories, \(food.Protein)g of protein, \(food.Carbohydrates) Carbs, \(food.Sugars)g of sugars",
                totalCalories: 0,
                duration: 0,
                NumExcersises: 0
            )
        )

    }
     func deleteItems(at offsets: IndexSet) {
            items.remove(atOffsets: offsets)
         if HealthManager.shared.calories < 0{
             HealthManager.shared.calories = 0
         }
         if HealthManager.shared.protein < 0{
             HealthManager.shared.protein = 0
         }
         if HealthManager.shared.sugars < 0{
             HealthManager.shared.sugars = 0
         }
         if HealthManager.shared.carbs < 0{
             HealthManager.shared.carbs = 0
         }
            persistenceManager.saveItems(items: items)
         
        }
    func deleteItemss(name:String) {
        persistenceManager.clearItem(byName: name)
        if HealthManager.shared.calories < 0{
            HealthManager.shared.calories = 0
        }
        if HealthManager.shared.protein < 0{
            HealthManager.shared.protein = 0
        }
        if HealthManager.shared.sugars < 0{
            HealthManager.shared.sugars = 0
        }
        if HealthManager.shared.carbs < 0{
            HealthManager.shared.carbs = 0
        }
       }
    
    
    struct ExpandableBoxView: View {
        var item: ExcListItem
        let persistenceManager: PersistenceManager
        var body: some View {
            VStack(alignment: .leading) {
                
                HStack {
                    Spacer().frame(width: 20)
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(1) // Limit title to one line
                        .truncationMode(.tail) // Truncate if it’s too long
                        .frame(maxWidth: .infinity, alignment: .leading) // Ensure full width
                    Spacer()
                    Image(systemName: "flame").foregroundStyle(Color.red)
                    Spacer().frame(width: 14)
                }
                
                
                if item.isExpanded {
                    Text(item.description)
                        .font(.subheadline)
                        .padding(.top, 5)
                        .frame(maxWidth: .infinity, alignment: .leading) // Align description to leading
                    
                    Spacer()
                    HStack{
                        Button(action: {
                            persistenceManager.clearItem(byName: item.title)
                            
                        }) {
                            Text("Remove")
                                .foregroundColor(.red).bold().fontDesign(.rounded)
                            
                        }
                        Spacer()
                        Button(action: {
//                            persistenceManager.clearItem(byName: item.title)
//                            item.isSaved.toggle()
                            
                        }) {
                        
                            Image(systemName: item.isSaved ? "star.fill" : "star").foregroundStyle(Color.yellow)
                            Text("Make Favorite").foregroundColor(.accentColor).bold().fontDesign(.rounded).background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).frame(width: 120, height: 40))
                            
                        }
                        
                    
                    }
                   
                    
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .shadow(radius: 1)
            .padding(.vertical, 5)
        }
    }

   

func geminii() async throws {
    
    let foodName = newItemName.uppercased()
    
    let config = GenerationConfig(
      temperature: 1,
      topP: 0.95,
      topK: 40,
      maxOutputTokens: 8192,
      responseMIMEType: "text/plain"
    )

    
    // Don't check your API key into source control!
    let apiKey = "AIzaSyD_X7ymdkDp0goekMxVfD3lOsO1yTGSgkU"
    
    
    let model = GenerativeModel(
      name: "gemini-2.0-flash",
      apiKey: apiKey,
      generationConfig: config
    )
    
    
    

    
    
    let chat = model.startChat(history: [
      ModelContent(
        role: "user",
        parts: [
          .text("you are gonna behave as a nutritionist. resposnd to this \"A user ate today 1 portion of banana, give me in a Json file the Name(return string) number of Protein(return int), Calories(return int), Sugars(return int), and Carbohydrates(return an int)\"\" skip the notes if no value found replace with 0 no comments")
        ]
      ),
      ModelContent(
        role: "model",
        parts: [
          .text("```json\n{\n  \"Name\": \"Banana (1 portion)\",\n  \"Protein\": 1,\n  \"Calories\": 105,\n  \"Sugars\": 14,\n  \"Carbohydrates\": 27\n}\n```\n")
        ]
      )
    ])
  
    Task {
        do {
            let message1 = "A user ate today \(self.number) \(self.quantity) of \(foodName), give me in a Json file the Name(return string) and all integers the number of Protein(int), Calories(int), Sugars(int), and Carbohydrates(int)"
            let response1 = try await chat.sendMessage(message1)
            try await extractFood(from: response1.text ?? "")
        } catch {
            print("Error: \(error)")
        }
        
            
            
    }
    
    

        
}

func extractFood(from response: String) async throws{
    // Remove the code block indicators from the JSON string
    var trimmedResponse = response.replacingOccurrences(of: "```json", with: "")
    
    trimmedResponse = trimmedResponse.replacingOccurrences(of: "```", with: "")
    trimmedResponse = trimmedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Convert the trimmed response to Data
    
    if let lastIndex = trimmedResponse.lastIndex(of: "}") {
        let substring = trimmedResponse[...lastIndex]
        trimmedResponse = String(substring)
    }
    
    print(trimmedResponse)
    guard let jsonData = trimmedResponse.data(using: .utf8) else {
        print("Error converting JSON string to data")
        return
    }
    
    // Decode the JSON data
    let jsonDecoder = JSONDecoder()
    Task{
        do {
            let nutritions = try jsonDecoder.decode(Food.self, from: jsonData)
            tempFood = nutritions
            addItem()
            HealthManager.shared.calories += tempFood?.Calories ?? 0
            HealthManager.shared.sugars += tempFood?.Sugars ?? 0
            HealthManager.shared.protein += tempFood?.Protein ?? 0
            HealthManager.shared.carbs += tempFood?.Carbohydrates ?? 0
            newItemName = ""
            self.number = 0
            self.quantity = ""
            buttonPressed = false
            print("Saved calories = \(tempFood?.Calories ?? 1)")
        } catch {
            print("Error decoding JSON: \(error.localizedDescription)")
            do { let nutritions = try jsonDecoder.decode(meal.self, from: jsonData)
                for i in 0..<nutritions.meal.count {
                    tempFood = nutritions.meal[i]
                    addItem()
                    HealthManager.shared.calories += tempFood?.Calories ?? 0
                    HealthManager.shared.protein += tempFood?.Protein ?? 0
                    HealthManager.shared.carbs += tempFood?.Carbohydrates ?? 0
                    HealthManager.shared.sugars += tempFood?.Sugars ?? 0
                }
            }
            catch{ print("Error decoding JSON meal: \(error.localizedDescription)")
            }
        }
    }

}

func handleBarcode(_ code: String) async {
    do {
        let food = try await BarcodeService.fetchFood(for: code)
        tempFood = food
        addItem()
        HealthManager.shared.calories += food.Calories
        HealthManager.shared.sugars += food.Sugars
        HealthManager.shared.protein += food.Protein
        HealthManager.shared.carbs += food.Carbohydrates
        buttonPressed = false
    } catch {
        print("Barcode error: \(error)")
        barcodeErrorMessage = error.localizedDescription
        showBarcodeError = true
    }
}
}

struct ListItem: View {
    var title: Food
    @State var isSaved = false
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack {
            HStack {
                Spacer().frame(width: 20)
                Text(title.Name).foregroundStyle(Color.white)
                Spacer()
                Image(systemName: "flame").foregroundStyle(Color.red)
                Spacer().frame(width: 14)
            }
            .frame(width: 390, height: 50)
            .background(Color.white.opacity(0.2))
            .clipShape(Capsule())
            .onTapGesture {
                withAnimation {
                    isExpanded.toggle()
                }
            }

            if isExpanded {
                VStack(alignment: .leading) {
                    Text("Details about \(title.Name)").foregroundStyle(Color.white)
                    Text("Additional information here...").foregroundStyle(Color.white)
                }
                .padding()
                .background(Color.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .transition(.slide)
            }
        }
        .padding(.horizontal)
    }
}




