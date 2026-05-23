//
//  NutritionView.swift
//  Gym-app-ioss
//

import SwiftUI
import RiveRuntime

struct NutritionView: View {
    @State var buttonPressed = false
    @State var buttonPressed2 = false
    @StateObject var viewModel: ListViewModel
    @StateObject var viewModel2: ListViewModel
    @State var expandedIndexes = Set<Int>()
    @State private var items: [Food] = []
    @State private var newItemName: String = ""
    @Binding var persistenceManager: PersistenceManager
    @State var tempFood: Food?
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

    // ── Image analysis ────────────────────────────────────────────────────────
    @State private var showImagePicker = false
    @State private var capturedImage: UIImage? = nil
    @State private var isAnalyzingImage = false
    @State private var showImageError = false
    @State private var imageErrorMessage = ""

    var email: String

    var body: some View {
        if buttonPressed {
            NavigationView {
                ZStack {
                    VStack {
                        HStack {
                            VStack {
                                if buttonPressed2 {
                                    // ── Manual entry form ─────────────────────
                                    Form {
                                        Section(header: Text("Name").foregroundColor(.white)) {
                                            TextField("Food Name", text: $newItemName)
                                                .listRowBackground(Color.gray)
                                                .foregroundColor(.white)
                                        }
                                        .foregroundColor(.white)
                                        Section(header: Text("Calories")) {
                                            TextField("Calories", text: Binding<String>(
                                                get: { String(Calories) },
                                                set: { if let v = Int($0) { Calories = v } }
                                            ))
                                            .keyboardType(.numberPad)
                                            .listRowBackground(Color.gray)
                                        }
                                        .foregroundColor(.white).bold()
                                        Section(header: Text("Sugars")) {
                                            TextField("Sugars", text: Binding<String>(
                                                get: { String(Sugar) },
                                                set: { if let v = Int($0) { Sugar = v } }
                                            ))
                                            .keyboardType(.numberPad)
                                            .listRowBackground(Color.gray)
                                        }
                                        .foregroundColor(.white).bold()
                                        Section(header: Text("Carbs")) {
                                            TextField("Carbs", text: Binding<String>(
                                                get: { String(Carbs) },
                                                set: { if let v = Int($0) { Carbs = v } }
                                            ))
                                            .keyboardType(.numberPad)
                                            .listRowBackground(Color.gray)
                                        }
                                        .foregroundColor(.white).bold()
                                        Section(header: Text("Protein")) {
                                            TextField("Protein", text: Binding<String>(
                                                get: { String(Protein) },
                                                set: { if let v = Int($0) { Protein = v } }
                                            ))
                                            .keyboardType(.numberPad)
                                            .listRowBackground(Color.gray)
                                        }
                                        .foregroundColor(.white).bold()
                                    }
                                    .frame(width: 450, height: 500)
                                    .foregroundColor(.white).bold()
                                } else {
                                    // ── AI text entry form ────────────────────
                                    Form {
                                        Section(header: Text("Name").foregroundColor(.white)) {
                                            TextField("Food Name", text: $newItemName)
                                                .listRowBackground(Color.gray)
                                                .foregroundColor(.white)
                                        }
                                        .foregroundColor(.white)
                                        Section(header: Text("Number")) {
                                            TextField("Number", text: Binding<String>(
                                                get: { String(number) },
                                                set: { if let v = Int($0) { number = v } }
                                            ))
                                            .keyboardType(.numberPad)
                                            .listRowBackground(Color.gray)
                                        }
                                        .foregroundColor(.white).bold()
                                        Section(header: Text("Quantity or description").foregroundColor(.white)) {
                                            TextField("Quantity or description", text: $quantity)
                                                .listRowBackground(Color.gray)
                                                .foregroundColor(.white)
                                        }
                                        .foregroundColor(.white)
                                        .scrollContentBackground(.hidden)
                                    }
                                    .scrollContentBackground(.hidden)
                                    .frame(width: 450, height: 300)
                                    .foregroundColor(.white).bold()
                                }
                            }
                        }

                        Spacer()

                        // ── Action buttons row ────────────────────────────────
                        HStack {
                            Spacer()

                            // Custom manual entry
                            Button {
                                buttonPressed2 = true
                            } label: {
                                Text("Custom")
                                    .font(.title3)
                                    .foregroundStyle(Color.white)
                                    .background(
                                        RoundedRectangle(cornerRadius: 90)
                                            .foregroundStyle(Color.accentColor)
                                            .frame(width: 100, height: 50)
                                    )
                                    .padding(.bottom)
                            }

                            Spacer()

                            // Barcode scanner
                            Button {
                                showScanner = true
                            } label: {
                                Image(systemName: "barcode.viewfinder")
                                    .foregroundStyle(Color.white)
                                    .font(.title2)
                                    .frame(width: 40, height: 40)
                            }

                            Spacer()

                            // Camera / photo analysis
                            Button {
                                showImagePicker = true
                            } label: {
                                Image(systemName: "camera.fill")
                                    .foregroundStyle(Color.white)
                                    .font(.title2)
                                    .frame(width: 40, height: 40)
                            }

                            Spacer()

                            // Add / confirm
                            Button {
                                if buttonPressed2 {
                                    tempFood = Food(
                                        Name: newItemName,
                                        Calories: Calories,
                                        Sugars: Sugar,
                                        Carbohydrates: Carbs,
                                        Protein: Protein
                                    )
                                    addItem()
                                    HealthManager.shared.calories += tempFood?.Calories ?? 0
                                    HealthManager.shared.sugars   += tempFood?.Sugars ?? 0
                                    HealthManager.shared.protein  += tempFood?.Protein ?? 0
                                    HealthManager.shared.carbs    += tempFood?.Carbohydrates ?? 0
                                    newItemName   = ""
                                    self.number   = 0
                                    self.quantity = ""
                                    buttonPressed = false
                                } else {
                                    Task { try await geminii() }
                                }
                            } label: {
                                Text("Add")
                                    .font(.title3)
                                    .foregroundStyle(Color.white)
                                    .background(
                                        RoundedRectangle(cornerRadius: 90)
                                            .foregroundStyle(Color.red)
                                            .frame(width: 100, height: 50)
                                    )
                                    .padding(.bottom)
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
                            Task { await handleBarcode(code) }
                            showScanner = false
                        }
                    }
                    .sheet(isPresented: $showImagePicker) {
                        CameraPickerView { image in
                            capturedImage = image
                            showImagePicker = false
                            Task { await analyzeFoodFromImage(image) }
                        }
                    }
                    .alert("Barcode Error", isPresented: $showBarcodeError) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text(barcodeErrorMessage)
                    }
                    .alert("Image Analysis Error", isPresented: $showImageError) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text(imageErrorMessage)
                    }

                    // ── Analyzing overlay ─────────────────────────────────────
                    if isAnalyzingImage {
                        ZStack {
                            Color.black.opacity(0.5).ignoresSafeArea()
                            VStack(spacing: 16) {
                                ProgressView()
                                    .progressViewStyle(
                                        CircularProgressViewStyle(tint: .white)
                                    )
                                    .scaleEffect(1.8)
                                Text("Analyzing food...")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .fontDesign(.rounded)
                            }
                            .padding(36)
                            .background(Color.gray.opacity(0.85))
                            .cornerRadius(20)
                        }
                    }
                }
            }

        } else {
            // ── Food log list ─────────────────────────────────────────────────
            VStack {
                HStack {
                    Spacer().frame(width: 20)
                    if viewModel.items.isEmpty {
                        HStack {
                            Text("No food added yet!")
                                .font(.title)
                                .fontWeight(.bold)
                                .italic()
                                .fontDesign(.rounded)
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
                    } else {
                        Text("Today you had: ")
                            .font(.title)
                            .fontWeight(.bold)
                            .italic()
                    }
                    Spacer()
                    Button {
                        buttonPressed = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.white)
                            .font(.title)
                            .frame(width: 50, height: 80)
                            .clipShape(Circle())
                    }
                    Spacer().frame(width: 20)
                }

                ScrollView {
                    ForEach(viewModel.items) { item in
                        ExpandableBoxView(
                            item: item,
                            persistenceManager: self.persistenceManager,
                            email: email
                        )
                        .onTapGesture { viewModel.toggleExpand(for: item) }
                        .animation(.easeInOut, value: item.isExpanded)
                    }
                }
                Spacer()
            }
            .onAppear {
                viewModel.items.removeAll()
                let temp = persistenceManager.loadItems()
                for i in 0..<temp.count {
                    viewModel.items.append(ExcListItem(
                        title: temp[i].Name,
                        description: "This food with this portion has approx: \(temp[i].Calories) calories, \(temp[i].Protein)g of protein, \(temp[i].Carbohydrates) Carbs, \(temp[i].Sugars)g of sugars",
                        totalCalories: 0,
                        duration: 0,
                        NumExcersises: 0
                    ))
                }
            }
            .alert("Barcode Error", isPresented: $showBarcodeError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(barcodeErrorMessage)
            }
        }
    }

    // ── Add item to list + persistence ────────────────────────────────────────
    private func addItem() {
        guard let food = tempFood else { return }
        items.append(food)
        persistenceManager.saveItems(items: items)
        viewModel.items.append(ExcListItem(
            title: food.Name,
            description: "This food with this portion has approx: \(food.Calories) calories, \(food.Protein)g of protein, \(food.Carbohydrates) Carbs, \(food.Sugars)g of sugars",
            totalCalories: 0,
            duration: 0,
            NumExcersises: 0
        ))
    }

    func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        clampHealth()
        persistenceManager.saveItems(items: items)
    }

    func deleteItemss(name: String) {
        persistenceManager.clearItem(byName: name)
        clampHealth()
    }

    private func clampHealth() {
        if HealthManager.shared.calories  < 0 { HealthManager.shared.calories  = 0 }
        if HealthManager.shared.protein   < 0 { HealthManager.shared.protein   = 0 }
        if HealthManager.shared.sugars    < 0 { HealthManager.shared.sugars    = 0 }
        if HealthManager.shared.carbs     < 0 { HealthManager.shared.carbs     = 0 }
    }

    // ── AI text food analysis ─────────────────────────────────────────────────
    func geminii() async throws {
        let urlString = Constants.baseURL + "/ai/analyzeFood"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "name":     newItemName,
            "number":   number,
            "quantity": quantity
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let food = try JSONDecoder().decode(Food.self, from: data)

        await MainActor.run {
            tempFood = food
            addItem()
            HealthManager.shared.calories += food.Calories
            HealthManager.shared.sugars   += food.Sugars
            HealthManager.shared.protein  += food.Protein
            HealthManager.shared.carbs    += food.Carbohydrates
            newItemName   = ""
            self.number   = 0
            self.quantity = ""
            buttonPressed = false
        }
    }

    // ── AI image food analysis ────────────────────────────────────────────────
    func analyzeFoodFromImage(_ image: UIImage) async {
        await MainActor.run { isAnalyzingImage = true }
        defer { Task { @MainActor in isAnalyzingImage = false } }

        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            await MainActor.run {
                imageErrorMessage = "Could not process the photo."
                showImageError = true
            }
            return
        }

        let base64String = imageData.base64EncodedString()

        do {
            let urlString = Constants.baseURL + "/ai/analyzeFoodImage"
            guard let url = URL(string: urlString) else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 60
            let session = URLSession(configuration: config)

            let body: [String: Any] = [
                "imageBase64": base64String,
                "mimeType":    "image/jpeg"
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, _) = try await session.data(for: request)
            let food = try JSONDecoder().decode(Food.self, from: data)

            await MainActor.run {
                tempFood = food
                addItem()
                HealthManager.shared.calories += food.Calories
                HealthManager.shared.sugars   += food.Sugars
                HealthManager.shared.protein  += food.Protein
                HealthManager.shared.carbs    += food.Carbohydrates
                buttonPressed = false
            }
        } catch {
            await MainActor.run {
                imageErrorMessage = "Could not analyze the photo: \(error.localizedDescription)"
                showImageError = true
            }
        }
    }

    // ── Barcode handler (unchanged) ───────────────────────────────────────────
    func handleBarcode(_ code: String) async {
        do {
            let food = try await BarcodeService.fetchFood(for: code)
            tempFood = food
            addItem()
            HealthManager.shared.calories += food.Calories
            HealthManager.shared.sugars   += food.Sugars
            HealthManager.shared.protein  += food.Protein
            HealthManager.shared.carbs    += food.Carbohydrates
            buttonPressed = false
        } catch {
            barcodeErrorMessage = error.localizedDescription
            showBarcodeError = true
        }
    }

    // ── Expandable food row ───────────────────────────────────────────────────
    struct ExpandableBoxView: View {
        var item: ExcListItem
        let persistenceManager: PersistenceManager
        let email: String
        @State private var isSaved: Bool

        init(item: ExcListItem, persistenceManager: PersistenceManager, email: String) {
            self.item = item
            self.persistenceManager = persistenceManager
            self.email = email
            _isSaved = State(initialValue:
                persistenceManager.loadFavorites().contains(where: { $0.Name == item.title })
            )
        }

        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Spacer().frame(width: 20)
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    Image(systemName: "flame").foregroundStyle(Color.red)
                    Spacer().frame(width: 14)
                }

                if item.isExpanded {
                    Text(item.description)
                        .font(.subheadline)
                        .padding(.top, 5)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()

                    HStack {
                        Button {
                            persistenceManager.clearItem(byName: item.title)
                        } label: {
                            Text("Remove")
                                .foregroundColor(.red)
                                .bold()
                                .fontDesign(.rounded)
                        }

                        Spacer()

                        Button {
                            if let food = persistenceManager.getItem(byName: item.title) {
                                if isSaved {
                                    persistenceManager.removeFavorite(byName: food.Name)
                                    isSaved = false
                                } else {
                                    persistenceManager.addFavorite(food: food)
                                    Task { await persistenceManager.sendFavorites(email: email) }
                                    isSaved = true
                                }
                            }
                        } label: {
                            Image(systemName: isSaved ? "star.fill" : "star")
                                .foregroundStyle(Color.yellow)
                            Text("Make Favorite")
                                .foregroundColor(.accentColor)
                                .bold()
                                .fontDesign(.rounded)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 120, height: 40)
                                )
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
}

// ── Camera picker ─────────────────────────────────────────────────────────────
struct CameraPickerView: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        // Use .camera on device, .photoLibrary on simulator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera)
            ? .camera
            : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImage: (UIImage) -> Void
        init(onImage: @escaping (UIImage) -> Void) { self.onImage = onImage }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            picker.dismiss(animated: true)
            if let image = info[.originalImage] as? UIImage {
                onImage(image)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// ── Preview ───────────────────────────────────────────────────────────────────

