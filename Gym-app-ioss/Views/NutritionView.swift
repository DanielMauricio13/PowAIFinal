import SwiftUI
import RiveRuntime

struct NutritionView: View {
    enum EntryMode: String, CaseIterable, Identifiable {
        case ai = "Smart"
        case manual = "Manual"
        var id: String { rawValue }
    }

    @State var buttonPressed = false
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
    @State private var entryMode: EntryMode = .ai

    @State private var showImagePicker = false
    @State private var capturedImage: UIImage? = nil
    @State private var isAnalyzingImage = false
    @State private var showImageError = false
    @State private var imageErrorMessage = ""

    // ── NEW ──────────────────────────────────────────────────────────────────
    @State private var favoriteItems: [Food] = []
    // ─────────────────────────────────────────────────────────────────────────

    var email: String

    var body: some View {
        if buttonPressed {
            NavigationView {
                ZStack {
                    AppBackgroundView()

                    VStack(spacing: 18) {
                        Text("Add food")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // ── NEW: Favorites shelf ─────────────────────────────
                        if !favoriteItems.isEmpty {
                            favoritesShelf
                        }
                        // ────────────────────────────────────────────────────

                        Picker("Entry Mode", selection: $entryMode) {
                            ForEach(EntryMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        Group {
                            if entryMode == .manual {
                                manualForm
                            } else {
                                smartForm
                            }
                        }

                        actionButtons
                        Spacer(minLength: 0)
                    }
                    .padding()
                    .navigationBarTitleDisplayMode(.inline)
                    .onAppear {
                        items = persistenceManager.loadItems()
                        favoriteItems = persistenceManager.loadFavorites()   // ← NEW
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
                    } message: { Text(barcodeErrorMessage) }
                    .alert("Image Analysis Error", isPresented: $showImageError) {
                        Button("OK", role: .cancel) {}
                    } message: { Text(imageErrorMessage) }

                    if isAnalyzingImage {
                        ZStack {
                            Color.black.opacity(0.5).ignoresSafeArea()
                            VStack(spacing: 16) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
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
            VStack(spacing: 12) {
                HStack {
                    Text(viewModel.items.isEmpty ? "No food added yet" : "Today's foods")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Button { buttonPressed = true } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.title)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal)

                if viewModel.items.isEmpty {
                    ContentUnavailableView(
                        "Start logging meals",
                        systemImage: "fork.knife",
                        description: Text("Tap + to add using Smart, Manual, barcode, or camera.")
                    )
                    .foregroundStyle(.white)
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(viewModel.items) { item in
                                ExpandableBoxView(
                                    item: item,
                                    persistenceManager: self.persistenceManager,
                                    email: email,
                                    onRemove: {
                                        removeItem(named: item.title)
                                    }
                                )
                                .onTapGesture { viewModel.toggleExpand(for: item) }
                                .animation(.easeInOut, value: item.isExpanded)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .onAppear {
                reloadItems()
            }
            .alert("Barcode Error", isPresented: $showBarcodeError) {
                Button("OK", role: .cancel) {}
            } message: { Text(barcodeErrorMessage) }
        }
    }

    // MARK: - Favorites Shelf ─────────────────────────────────────────────────

    private var favoritesShelf: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Favorites", systemImage: "star.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.yellow)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(favoriteItems, id: \.Name) { food in
                        FavoriteCard(food: food) {
                            // Quick-add
                            tempFood = food
                            addItem()
                            HealthManager.shared.calories     += food.Calories
                            HealthManager.shared.sugars       += food.Sugars
                            HealthManager.shared.protein      += food.Protein
                            HealthManager.shared.carbs        += food.Carbohydrates
                            buttonPressed = false
                        } onRemove: {
                            // Remove from favorites
                            persistenceManager.removeFavorite(byName: food.Name)
                            favoriteItems = persistenceManager.loadFavorites()
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .cornerRadius(14)
    }

    // MARK: - Favorite Card ───────────────────────────────────────────────────

    struct FavoriteCard: View {
        let food: Food
        let onAdd: () -> Void
        let onRemove: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(food.Name)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .frame(maxWidth: 90, alignment: .leading)

                    Spacer(minLength: 0)

                    // Remove from favorites
                    Button(action: onRemove) {
                        Image(systemName: "star.slash.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }

                Text("\(food.Calories) kcal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    MacroPill(label: "P", value: food.Protein, color: .blue)
                    MacroPill(label: "C", value: food.Carbohydrates, color: .orange)
                    MacroPill(label: "S", value: food.Sugars, color: .pink)
                }

                // Quick-add button
                Button(action: onAdd) {
                    Label("Add", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
                .tint(.accentColor)
            }
            .padding(10)
            .frame(width: 130)
            .background(.regularMaterial)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.yellow.opacity(0.35), lineWidth: 1)
            )
        }
    }

    // MARK: - Macro Pill (helper) ─────────────────────────────────────────────

    struct MacroPill: View {
        let label: String
        let value: Int
        let color: Color

        var body: some View {
            Text("\(label) \(value)g")
                .font(.system(size: 9, weight: .medium))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(color.opacity(0.15))
                .foregroundStyle(color)
                .cornerRadius(6)
        }
    }

    // MARK: - Existing subviews (unchanged) ───────────────────────────────────

    private var smartForm: some View {
        VStack(spacing: 10) {
            TextField("Food name", text: $newItemName)
                .textFieldStyle(.roundedBorder)
            HStack {
                TextField("Number", text: Binding<String>(
                    get: { number == 0 ? "" : String(number) },
                    set: { number = Int($0) ?? 0 }
                ))
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)

                TextField("Qty / description", text: $quantity)
                    .textFieldStyle(.roundedBorder)
            }
            Text("Use Smart mode when you don't know exact macros. We'll estimate for you.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.75))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .cornerRadius(14)
    }

    private var manualForm: some View {
        VStack(spacing: 10) {
            TextField("Food name", text: $newItemName)
                .textFieldStyle(.roundedBorder)
            HStack {
                macroField("Calories", value: $Calories)
                macroField("Sugar", value: $Sugar)
            }
            HStack {
                macroField("Carbs", value: $Carbs)
                macroField("Protein", value: $Protein)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .cornerRadius(14)
    }

    private func macroField(_ title: String, value: Binding<Int>) -> some View {
        TextField(title, text: Binding<String>(
            get: { value.wrappedValue == 0 ? "" : String(value.wrappedValue) },
            set: { value.wrappedValue = Int($0) ?? 0 }
        ))
        .keyboardType(.numberPad)
        .textFieldStyle(.roundedBorder)
    }

    private var actionButtons: some View {
        HStack(spacing: 24) {
            Button { showScanner = true } label: {
                Label("Barcode", systemImage: "barcode.viewfinder")
            }
            .buttonStyle(.bordered)

            Button { showImagePicker = true } label: {
                Label("Camera", systemImage: "camera.fill")
            }
            .buttonStyle(.bordered)

            Button {
                if entryMode == .manual {
                    tempFood = Food(Name: newItemName, Calories: Calories, Sugars: Sugar, Carbohydrates: Carbs, Protein: Protein)
                    addItem()
                    HealthManager.shared.calories += tempFood?.Calories ?? 0
                    HealthManager.shared.sugars   += tempFood?.Sugars ?? 0
                    HealthManager.shared.protein  += tempFood?.Protein ?? 0
                    HealthManager.shared.carbs    += tempFood?.Carbohydrates ?? 0
                    resetForm()
                    buttonPressed = false
                } else {
                    Task { try await geminii() }
                }
            } label: {
                Label("Add Food", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Helpers (unchanged) ─────────────────────────────────────────────

    private func resetForm() {
        newItemName = ""; number = 0; quantity = ""
        Calories = 0; Sugar = 0; Carbs = 0; Protein = 0
    }

    private func addItem() {
        guard let food = tempFood else { return }
        items.append(food)
        persistenceManager.saveItems(items: items)
        viewModel.items.append(ExcListItem(
            title: food.Name,
            description: "This food with this portion has approx: \(food.Calories) calories, \(food.Protein)g of protein, \(food.Carbohydrates)g carbs, \(food.Sugars)g sugars",
            totalCalories: 0, duration: 0, NumExcersises: 0
        ))
    }

    private func reloadItems() {
        items = persistenceManager.loadItems()
        viewModel.items = items.map { food in
            ExcListItem(
                title: food.Name,
                description: "This food with this portion has approx: \(food.Calories) calories, \(food.Protein)g of protein, \(food.Carbohydrates)g carbs, \(food.Sugars)g sugars",
                totalCalories: 0,
                duration: 0,
                NumExcersises: 0
            )
        }
    }

    private func removeItem(named name: String) {
        persistenceManager.clearItem(byName: name)
        clampHealth()
        reloadItems()
    }

    func deleteItems(at offsets: IndexSet) { items.remove(atOffsets: offsets); clampHealth(); persistenceManager.saveItems(items: items) }
    func deleteItemss(name: String) { removeItem(named: name) }
    private func clampHealth() {
        if HealthManager.shared.calories < 0 { HealthManager.shared.calories = 0 }
        if HealthManager.shared.protein  < 0 { HealthManager.shared.protein  = 0 }
        if HealthManager.shared.sugars   < 0 { HealthManager.shared.sugars   = 0 }
        if HealthManager.shared.carbs    < 0 { HealthManager.shared.carbs    = 0 }
    }

    func geminii() async throws {
        let urlString = Constants.baseURL + "/ai/analyzeFood"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["name": newItemName, "number": number, "quantity": quantity]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        let food = try JSONDecoder().decode(Food.self, from: data)
        await MainActor.run {
            tempFood = food; addItem()
            HealthManager.shared.calories += food.Calories
            HealthManager.shared.sugars   += food.Sugars
            HealthManager.shared.protein  += food.Protein
            HealthManager.shared.carbs    += food.Carbohydrates
            resetForm(); buttonPressed = false
        }
    }

    func analyzeFoodFromImage(_ image: UIImage) async {
        await MainActor.run { isAnalyzingImage = true }
        defer { Task { @MainActor in isAnalyzingImage = false } }
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            await MainActor.run { imageErrorMessage = "Could not process the photo."; showImageError = true }
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
            let body: [String: Any] = ["imageBase64": base64String, "mimeType": "image/jpeg"]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, _) = try await session.data(for: request)
            let food = try JSONDecoder().decode(Food.self, from: data)
            await MainActor.run {
                tempFood = food; addItem()
                HealthManager.shared.calories += food.Calories
                HealthManager.shared.sugars   += food.Sugars
                HealthManager.shared.protein  += food.Protein
                HealthManager.shared.carbs    += food.Carbohydrates
                buttonPressed = false
            }
        } catch {
            await MainActor.run { imageErrorMessage = "Could not analyze the photo: \(error.localizedDescription)"; showImageError = true }
        }
    }

    func handleBarcode(_ code: String) async {
        do {
            let food = try await BarcodeService.fetchFood(for: code)
            tempFood = food; addItem()
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

    // MARK: - Expandable row (unchanged) ──────────────────────────────────────

    struct ExpandableBoxView: View {
        var item: ExcListItem
        let persistenceManager: PersistenceManager
        let email: String
        let onRemove: () -> Void
        @State private var isSaved: Bool

        init(item: ExcListItem, persistenceManager: PersistenceManager, email: String, onRemove: @escaping () -> Void) {
            self.item = item
            self.persistenceManager = persistenceManager
            self.email = email
            self.onRemove = onRemove
            _isSaved = State(initialValue: persistenceManager.loadFavorites().contains(where: { $0.Name == item.title }))
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(item.isExpanded ? 180 : 0))
                        .foregroundStyle(.white.opacity(0.65))
                }

                if item.isExpanded {
                    Text(item.description).font(.subheadline).foregroundStyle(.white.opacity(0.78))
                    HStack {
                        Button("Remove", action: onRemove)
                            .foregroundColor(.red)
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
                            Label(isSaved ? "Favorited" : "Favorite",
                                  systemImage: isSaved ? "star.fill" : "star")
                                .foregroundStyle(.yellow)
                        }
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .cornerRadius(12)
        }
    }
}

// MARK: - CameraPickerView (unchanged) ────────────────────────────────────────

struct CameraPickerView: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImage: (UIImage) -> Void
        init(onImage: @escaping (UIImage) -> Void) { self.onImage = onImage }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            if let image = info[.originalImage] as? UIImage { onImage(image) }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
    }
}
