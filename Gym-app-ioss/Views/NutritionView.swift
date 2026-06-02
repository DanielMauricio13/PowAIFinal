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
    @State var caloriesInput: Int = 0
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
    @State private var showMealsWindow = false

    // ── NEW ──────────────────────────────────────────────────────────────────
    @State private var favoriteItems: [Food] = []
    // ─────────────────────────────────────────────────────────────────────────

    var email: String
    var mainUser: User? = nil

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
                    Button { showMealsWindow = true } label: {
                        nutritionHeaderActionLabel("Meals", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)

                    Button { buttonPressed = true } label: {
                        nutritionHeaderActionLabel("Food", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)

                Group {
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                compactNutritionGoalsFooter
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                reloadItems()
            }
            .alert("Barcode Error", isPresented: $showBarcodeError) {
                Button("OK", role: .cancel) {}
            } message: { Text(barcodeErrorMessage) }
            .sheet(isPresented: $showMealsWindow) {
                MealsWindow { meal in
                    addMealToDailyNutrition(meal)
                }
            }
        }
    }

    private func nutritionHeaderActionLabel(_ title: LocalizedStringKey, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .frame(width: 112, height: 40)
            .background(
                LinearGradient(colors: [.red, .orange],
                               startPoint: .leading,
                               endPoint: .trailing),
                in: Capsule()
            )
            .shadow(color: .orange.opacity(0.22), radius: 8, y: 4)
    }

    private var compactNutritionGoalsFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Daily goals", systemImage: "flame.fill")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                NavigationLink {
                    NutritionTrackerView(
                        email: mainUser?.email ?? "",
                        user: mainUser ?? User(id: nil, firstName: "", lastName: "", membershipStatus: "trial")
                    )
                } label: {
                    Label("Tracker", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            LinearGradient(colors: [.red, .orange],
                                           startPoint: .leading, endPoint: .trailing),
                            in: Capsule()
                        )
                }
            }

            GeometryReader { proxy in
                let spacing = proxy.size.width < 330 ? CGFloat(6) : CGFloat(10)
                let ringWidth = max(CGFloat(58), (proxy.size.width - (spacing * 3)) / 4)
                let ringDiameter = min(CGFloat(62), max(CGFloat(44), ringWidth - 16))

                HStack(spacing: spacing) {
                    CompactNutritionGoalRing(
                        title: "Calories",
                        value: HealthManager.shared.calories,
                        goal: mainUser?.DailyCalories ?? 1,
                        emoji: "🔥",
                        color: .red,
                        diameter: ringDiameter,
                        width: ringWidth
                    )

                    CompactNutritionGoalRing(
                        title: "Protein",
                        value: HealthManager.shared.protein,
                        goal: mainUser?.DailyProtein ?? 1,
                        emoji: "🍗",
                        color: .orange,
                        diameter: ringDiameter,
                        width: ringWidth
                    )

                    CompactNutritionGoalRing(
                        title: "Carbs",
                        value: HealthManager.shared.carbs,
                        goal: mainUser?.carbs ?? 1,
                        emoji: "🥐",
                        color: .yellow,
                        diameter: ringDiameter,
                        width: ringWidth
                    )

                    CompactNutritionGoalRing(
                        title: "Sugar",
                        value: HealthManager.shared.sugars,
                        goal: mainUser?.sugars ?? 1,
                        emoji: "🍭",
                        color: .pink,
                        diameter: ringDiameter,
                        width: ringWidth
                    )
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
            }
            .frame(height: AdaptiveLayout.scaled(122, compact: 106))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.26))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal)
        .padding(.bottom, 4)
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
                        .minimumScaleFactor(0.72)
                        .allowsTightening(true)
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
                macroField("Calories", value: $caloriesInput)
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
                    tempFood = Food(Name: newItemName, Calories: caloriesInput, Sugars: Sugar, Carbohydrates: Carbs, Protein: Protein)
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
        caloriesInput = 0; Sugar = 0; Carbs = 0; Protein = 0
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

    private func addMealToDailyNutrition(_ meal: MealDTO) {
        let food = Food(
            Name: meal.name,
            Calories: meal.macros.calories,
            Sugars: meal.macros.sugars,
            Carbohydrates: meal.macros.carbs,
            Protein: meal.macros.protein
        )
        tempFood = food
        addItem()
        HealthManager.shared.calories += food.Calories
        HealthManager.shared.sugars += food.Sugars
        HealthManager.shared.protein += food.Protein
        HealthManager.shared.carbs += food.Carbohydrates
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
        let optimizedImage = image.resizedForFoodAnalysis(maxDimension: 1024)
        guard let imageData = optimizedImage.jpegData(compressionQuality: 0.70) else {
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

private struct CompactNutritionGoalRing: View {
    let title: String
    let value: Int
    let goal: Int
    let emoji: String
    let color: Color
    let diameter: CGFloat
    let width: CGFloat

    private var strokeWidth: CGFloat {
        max(6, min(8, diameter * 0.13))
    }

    private var ringFrame: CGFloat {
        diameter + strokeWidth + 4
    }

    private var percentFontSize: CGFloat {
        max(10, min(13, diameter * 0.21))
    }

    private var titleFontSize: CGFloat {
        max(9, min(11, width * 0.14))
    }

    private var valueFontSize: CGFloat {
        max(8, min(10, width * 0.13))
    }

    private var progressFraction: CGFloat {
        guard goal > 0 else { return 0 }
        return min(CGFloat(value) / CGFloat(goal), 1)
    }

    private var progressPercent: Int {
        guard goal > 0 else { return 0 }
        return min(value * 100 / goal, 100)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.14), lineWidth: strokeWidth)
                    .frame(width: diameter, height: diameter)

                Circle()
                    .trim(from: 0, to: progressFraction)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: diameter, height: diameter)
                    .rotationEffect(.degrees(-90))

                Text("\(progressPercent)%")
                    .font(.system(size: percentFontSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(width: ringFrame, height: ringFrame)

            Text("\(title) \(emoji)")
                .font(.system(size: titleFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text("\(value)/\(goal)")
                .font(.system(size: valueFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: width)
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

private extension UIImage {
    func resizedForFoodAnalysis(maxDimension: CGFloat) -> UIImage {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else { return self }

        let scale = maxDimension / longestSide
        let targetSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

private struct MealMacrosDTO: Codable {
    let calories: Int
    let protein: Int
    let carbs: Int
    let sugars: Int
    let fats: Int?
}

private struct MealDTO: Identifiable, Codable {
    let id: UUID?
    let name: String
    let macros: MealMacrosDTO
    let ingredients: [String]
    let preparationDescription: String
    let estimatedTimeMinutes: Int
    let difficulty: String
    let mealType: String
    let isEsp: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case macros
        case ingredients
        case preparationDescription
        case preparationDescriptionSnake = "preparation_description"
        case estimatedTimeMinutes
        case estimatedTimeMinutesSnake = "estimated_time_minutes"
        case difficulty
        case mealType
        case mealTypeSnake = "meal_type"
        case isEsp
        case isEspSnake = "is_esp"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        macros = try container.decode(MealMacrosDTO.self, forKey: .macros)
        ingredients = try container.decode([String].self, forKey: .ingredients)
        preparationDescription = try container.decodeFlexibleString(.preparationDescription, .preparationDescriptionSnake)
        estimatedTimeMinutes = try container.decodeFlexibleInt(.estimatedTimeMinutes, .estimatedTimeMinutesSnake)
        difficulty = try container.decode(String.self, forKey: .difficulty)
        mealType = try container.decodeFlexibleString(.mealType, .mealTypeSnake)
        isEsp = try container.decodeFlexibleBool(.isEsp, .isEspSnake) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(macros, forKey: .macros)
        try container.encode(ingredients, forKey: .ingredients)
        try container.encode(preparationDescription, forKey: .preparationDescription)
        try container.encode(estimatedTimeMinutes, forKey: .estimatedTimeMinutes)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(mealType, forKey: .mealType)
        try container.encode(isEsp, forKey: .isEsp)
    }
}

private extension KeyedDecodingContainer where Key == MealDTO.CodingKeys {
    func decodeFlexibleString(_ primary: Key, _ fallback: Key) throws -> String {
        if let value = try decodeIfPresent(String.self, forKey: primary) {
            return value
        }
        return try decode(String.self, forKey: fallback)
    }

    func decodeFlexibleInt(_ primary: Key, _ fallback: Key) throws -> Int {
        if let value = try decodeIfPresent(Int.self, forKey: primary) {
            return value
        }
        return try decode(Int.self, forKey: fallback)
    }

    func decodeFlexibleBool(_ primary: Key, _ fallback: Key) throws -> Bool? {
        if let value = try decodeIfPresent(Bool.self, forKey: primary) {
            return value
        }
        return try decodeIfPresent(Bool.self, forKey: fallback)
    }
}

private struct CreateMealsRequest: Encodable {
    let ingredients: [String]
    let difficulty: String
    let mealType: String
    let isEsp: Bool
}

private enum MealsAPI {
    static func fetchMeals(isEsp: Bool) async throws -> [MealDTO] {
        guard let url = URL(string: Constants.baseURL + "meals") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.applyBearerToken()

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return try JSONDecoder().decode([MealDTO].self, from: data)
            .filter { $0.isEsp == isEsp }
    }

    static func createMeals(ingredients: [String], difficulty: String, mealType: String, isEsp: Bool) async throws -> [MealDTO] {
        guard let url = URL(string: Constants.baseURL + "meals") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.applyBearerToken()
        request.httpBody = try JSONEncoder().encode(CreateMealsRequest(
            ingredients: ingredients,
            difficulty: difficulty.lowercased(),
            mealType: mealType.lowercased(),
            isEsp: isEsp
        ))

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return try JSONDecoder().decode([MealDTO].self, from: data)
            .filter { $0.isEsp == isEsp }
    }

    private static func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}

private struct MealsWindow: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageManager = AppLanguageManager.shared
    @State private var meals: [MealDTO] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAddMeals = false
    @State private var addedMealName: String?
    @State private var selectedMealType = "All"
    @State private var selectedDifficulty = "All"

    let onAddMeal: (MealDTO) -> Void

    private let mealTypeOptions = ["All", "Breakfast", "Lunch", "Dinner"]
    private let difficultyOptions = ["All", "Easy", "Medium", "Hard"]

    private var isSpanishMeals: Bool {
        languageManager.prefersSpanish
    }

    private var filteredMeals: [MealDTO] {
        meals.filter { meal in
            let typeMatches = selectedMealType == "All" || meal.mealType.lowercased() == selectedMealType.lowercased()
            let difficultyMatches = selectedDifficulty == "All" || meal.difficulty.lowercased() == selectedDifficulty.lowercased()
            return typeMatches && difficultyMatches
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppBackgroundView()

                VStack(spacing: 16) {
                    if isLoading && meals.isEmpty {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.4)
                        Text("Loading meals...")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                    } else if meals.isEmpty {
                        Spacer()
                        ContentUnavailableView(
                            "No meals yet",
                            systemImage: "fork.knife",
                            description: Text("Tap + to generate meal ideas from ingredients you already have.")
                        )
                        .foregroundStyle(.white)
                        Spacer()
                    } else {
                        filterControls

                        if filteredMeals.isEmpty {
                            Spacer()
                            ContentUnavailableView(
                                "No matching meals",
                                systemImage: "line.3.horizontal.decrease.circle",
                                description: Text("Adjust the meal type or difficulty filters.")
                            )
                            .foregroundStyle(.white)
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 14) {
                                    ForEach(filteredMeals) { meal in
                                        MealOptionCard(meal: meal) {
                                            onAddMeal(meal)
                                            addedMealName = meal.name
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 24)
                            }
                            .refreshable {
                                await loadMeals()
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("Meals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddMeals = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .foregroundStyle(.white)
                }
            }
            .task {
                await loadMeals()
            }
            .onChange(of: languageManager.selectedLanguage) { _, _ in
                Task { await loadMeals() }
            }
            .sheet(isPresented: $showAddMeals) {
                AddMealsIngredientsSheet { ingredients, difficulty, mealType in
                    try await createMeals(
                        ingredients: ingredients,
                        difficulty: difficulty,
                        mealType: mealType
                    )
                }
            }
            .alert("Meals Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .alert("Meal Added", isPresented: Binding(
                get: { addedMealName != nil },
                set: { if !$0 { addedMealName = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("\(addedMealName ?? "Meal") was added to today's nutrition.")
            }
        }
    }

    private var filterControls: some View {
        HStack(spacing: 10) {
            MealFilterMenu(
                title: "Meal Type",
                systemImage: "fork.knife",
                selection: $selectedMealType,
                options: mealTypeOptions
            )

            MealFilterMenu(
                title: "Difficulty",
                systemImage: "gauge.with.dots.needle.33percent",
                selection: $selectedDifficulty,
                options: difficultyOptions
            )
        }
        .padding(.horizontal)
    }

    @MainActor
    private func loadMeals() async {
        isLoading = true
        defer { isLoading = false }

        do {
            meals = try await MealsAPI.fetchMeals(isEsp: isSpanishMeals)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func createMeals(ingredients: [String], difficulty: String, mealType: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            let newMeals = try await MealsAPI.createMeals(
                ingredients: ingredients,
                difficulty: difficulty,
                mealType: mealType,
                isEsp: isSpanishMeals
            )
            meals = newMeals + meals.filter { existing in
                !newMeals.contains(where: { $0.id == existing.id })
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
}

private struct MealOptionCard: View {
    let meal: MealDTO
    let onAdd: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(meal.name)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .allowsTightening(true)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.leading, 34)

                        HStack(spacing: 8) {
                            MealBadge(text: localizedMealLabel(meal.mealType), systemImage: "clock")
                            MealBadge(text: localizedMealLabel(meal.difficulty), systemImage: "gauge.with.dots.needle.33percent")
                            MealBadge(text: "\(meal.estimatedTimeMinutes)m", systemImage: "timer")
                        }
                    }

                    Spacer()

                    Text("\(meal.macros.calories)")
                        .font(.title3.bold())
                        .foregroundStyle(.orange)
                        + Text(" kcal")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))
                }

                HStack(spacing: 8) {
                    MealMacroChip(label: "P", value: meal.macros.protein, color: .blue)
                    MealMacroChip(label: "C", value: meal.macros.carbs, color: .orange)
                    MealMacroChip(label: "S", value: meal.macros.sugars, color: .pink)
                    if let fats = meal.macros.fats {
                        MealMacroChip(label: "F", value: fats, color: .green)
                    }
                }

                Text(meal.ingredients.joined(separator: ", "))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(3)

                Text(meal.preparationDescription)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.25), radius: 5, y: 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add \(meal.name) to today's nutrition")
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .cornerRadius(14)
    }

    private func localizedMealLabel(_ value: String) -> String {
        AppLanguageManager.shared.localizedString(forKey: value.capitalized)
    }
}

private struct MealFilterMenu: View {
    let title: String
    let systemImage: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                } label: {
                    if option == selection {
                        Label {
                            Text(LocalizedStringKey(option))
                        } icon: {
                            Image(systemName: "checkmark")
                        }
                    } else {
                        Text(LocalizedStringKey(option))
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(title))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                    Text(LocalizedStringKey(selection))
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .allowsTightening(true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .cornerRadius(12)
        }
    }
}

private struct MealBadge: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.82))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.28))
            .cornerRadius(8)
    }
}

private struct MealMacroChip: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        Text("\(label) \(value)g")
            .font(.caption.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.16))
            .cornerRadius(9)
    }
}

private struct AddMealsIngredientsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var ingredientsText = ""
    @State private var selectedMealType = "Lunch"
    @State private var selectedDifficulty = "Easy"
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private let mealTypeOptions = ["Breakfast", "Lunch", "Dinner"]
    private let difficultyOptions = ["Easy", "Medium", "Hard"]

    let onSubmit: ([String], String, String) async throws -> Void

    var body: some View {
        NavigationView {
            ZStack {
                AppBackgroundView()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Ingredients")
                        .font(.headline)
                        .foregroundStyle(.white)

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $ingredientsText)
                            .frame(minHeight: 150)
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .background(Color.white.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
                            )
                            .cornerRadius(12)
                            .foregroundStyle(.white)

                        if ingredientsText.isEmpty {
                            Text("2 Chicken breast, rice,3 potatoes, broccoli...")
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.45))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 18)
                                .allowsHitTesting(false)
                        }
                    }

                    Text("Separate ingredients with commas or new lines.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.72))

                    HStack(spacing: 10) {
                        MealFilterMenu(
                            title: "Meal Type",
                            systemImage: "fork.knife",
                            selection: $selectedMealType,
                            options: mealTypeOptions
                        )

                        MealFilterMenu(
                            title: "Difficulty",
                            systemImage: "gauge.with.dots.needle.33percent",
                            selection: $selectedDifficulty,
                            options: difficultyOptions
                        )
                    }

                    Button {
                        submit()
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Label("Create Meals", systemImage: "sparkles")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSubmitting || parsedIngredients.isEmpty)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("New Meals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .alert("Create Meals Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var parsedIngredients: [String] {
        ingredientsText
            .split { $0 == "," || $0 == "\n" || $0 == ";" }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func submit() {
        let ingredients = parsedIngredients
        guard !ingredients.isEmpty else { return }

        isSubmitting = true
        Task {
            do {
                try await onSubmit(ingredients, selectedDifficulty, selectedMealType)
                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
