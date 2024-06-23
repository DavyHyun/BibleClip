import UIKit

enum Testament: Int {
    case oldTestament, newTestament
}

enum SelectionState {
    case testament, book, chapter, verses
}

struct Chapter: Codable {
    let chapter: String
    let verses: String
}

struct Book: Codable {
    let abbr: String
    let book: String
    let chapters: [Chapter]
}

class KeyboardViewController: UIInputViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    var currentTestament: Testament?
    var currentBook: String?
    var currentChapter: Int?
    var currentStartVerse: Int?
    var currentEndVerse: Int?
    var currentState: SelectionState = .testament
    
    let testamentData = ["Old Testament", "New Testament"]
    let oldTestamentBooks = [
        "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy",
        "Joshua", "Judges", "Ruth", "1 Samuel", "2 Samuel",
        "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra",
        "Nehemiah", "Esther", "Job", "Psalms", "Proverbs",
        "Ecclesiastes", "Song of Solomon", "Isaiah", "Jeremiah", "Lamentations",
        "Ezekiel", "Daniel", "Hosea", "Joel", "Amos",
        "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk",
        "Zephaniah", "Haggai", "Zechariah", "Malachi"
    ]
    
    let newTestamentBooks = [
        "Matthew", "Mark", "Luke", "John", "Acts",
        "Romans", "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians",
        "Philippians", "Colossians", "1 Thessalonians", "2 Thessalonians", "1 Timothy",
        "2 Timothy", "Titus", "Philemon", "Hebrews", "James",
        "1 Peter", "2 Peter", "1 John", "2 John", "3 John",
        "Jude", "Revelation"
    ]
    
    var chapters: [Int] = []
    var verses: [Int] = []
    var endVerses: [String] = []
    
    var allBooks: [Book] = []
    
    let pickerView = UIPickerView()
    let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Confirm", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let rangeLabel: UILabel = {
        let label = UILabel()
        label.text = "to"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    let pickerContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadJSONData()
        setupUI()
    }
    
    func loadJSONData() {
        if let url = Bundle.main.url(forResource: "bible", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                allBooks = try JSONDecoder().decode([Book].self, from: data)
            } catch {
                print("Error loading JSON data: \(error)")
            }
        }
    }
    
    func setupUI() {
        view.backgroundColor = .white
        setupPickerContainerView()
        setupPickerView()
        setupRangeLabel()
        setupConfirmButton()
    }
    
    func setupPickerContainerView() {
        view.addSubview(pickerContainerView)
        NSLayoutConstraint.activate([
            pickerContainerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            pickerContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pickerContainerView.widthAnchor.constraint(equalTo: view.widthAnchor),
            pickerContainerView.heightAnchor.constraint(equalToConstant: 150)
        ])
    }
    
    func setupPickerView() {
        pickerContainerView.addSubview(pickerView)
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pickerView.topAnchor.constraint(equalTo: pickerContainerView.topAnchor),
            pickerView.bottomAnchor.constraint(equalTo: pickerContainerView.bottomAnchor),
            pickerView.leadingAnchor.constraint(equalTo: pickerContainerView.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: pickerContainerView.trailingAnchor)
        ])
    }
    
    func setupRangeLabel() {
        pickerContainerView.addSubview(rangeLabel)
        NSLayoutConstraint.activate([
            rangeLabel.centerYAnchor.constraint(equalTo: pickerContainerView.centerYAnchor),
            rangeLabel.centerXAnchor.constraint(equalTo: pickerContainerView.centerXAnchor)
        ])
    }
    
    func setupConfirmButton() {
        view.addSubview(confirmButton)
        confirmButton.addTarget(self, action: #selector(confirmSelection), for: .touchUpInside)
        NSLayoutConstraint.activate([
            confirmButton.topAnchor.constraint(equalTo: pickerContainerView.bottomAnchor, constant: 10),
            confirmButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        confirmButton.isHidden = true
    }
    
    @objc func confirmSelection() {
        switch currentState {
        case .testament:
            currentTestament = Testament(rawValue: pickerView.selectedRow(inComponent: 0))
            currentState = .book
        case .book:
            let selectedBookName = currentTestament == .oldTestament ? oldTestamentBooks[pickerView.selectedRow(inComponent: 0)] : newTestamentBooks[pickerView.selectedRow(inComponent: 0)]
            currentBook = selectedBookName
            if let selectedBook = allBooks.first(where: { $0.book == selectedBookName }) {
                chapters = selectedBook.chapters.map { Int($0.chapter)! }
            }
            currentState = .chapter
        case .chapter:
            currentChapter = chapters[pickerView.selectedRow(inComponent: 0)]
            if let selectedBook = allBooks.first(where: { $0.book == currentBook }) {
                let selectedChapter = selectedBook.chapters.first { Int($0.chapter) == currentChapter }
                if let versesCount = selectedChapter?.verses {
                    verses = Array(1...Int(versesCount)!)
                    endVerses = ["None"] + Array(1...Int(versesCount)!).map { "\($0)" }
                }
            }
            currentState = .verses
        case .verses:
            currentStartVerse = pickerView.selectedRow(inComponent: 0) + 1
            let selectedEndRow = pickerView.selectedRow(inComponent: 1)
            if selectedEndRow == 0 {
                currentEndVerse = nil
                print("Selected Start Verse \(currentStartVerse!) of Chapter \(currentChapter!) in Book \(currentBook!). No End Verse selected.")
                fetchAndPasteVerse(book: currentBook, chapter: currentChapter, verse: currentStartVerse)
            } else {
                currentEndVerse = selectedEndRow
                if let currentChapter = currentChapter, let currentBook = currentBook, let startVerse = currentStartVerse, let endVerse = currentEndVerse {
                    if startVerse <= endVerse {
                        print("Selected Verses \(startVerse)-\(endVerse) of Chapter \(currentChapter) in Book \(currentBook)")
                        fetchAndPasteVerseRange(book: currentBook, chapter: currentChapter, startVerse: currentStartVerse, endVerse: endVerse)
                    } else {
                        print("Invalid range: start verse is greater than end verse")
                    }
                } else {
                    print("Chapter, Book, or Verses not set properly")
                }
            }
            currentState = .testament
        }
        pickerView.reloadAllComponents()
        rangeLabel.isHidden = currentState != .verses
        confirmButton.isHidden = true
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        switch currentState {
        case .verses:
            return 2
        default:
            return 1
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch currentState {
        case .testament:
            return testamentData.count
        case .book:
            return currentTestament == .oldTestament ? oldTestamentBooks.count : newTestamentBooks.count
        case .chapter:
            return chapters.count
        case .verses:
            return component == 0 ? verses.count : endVerses.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch currentState {
        case .testament:
            return testamentData[row]
        case .book:
            return currentTestament == .oldTestament ? oldTestamentBooks[row] : newTestamentBooks[row]
        case .chapter:
            return "Chapter \(chapters[row])"
        case .verses:
            return component == 0 ? "\(verses[row])" : endVerses[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        confirmButton.isHidden = false
    }
    
    func fetchAndPasteVerse(book: String?, chapter: Int?, verse: Int?) {
        guard let book = book, let chapter = chapter, let verse = verse else { return }
        let urlString = "https://bible-api.com/\(book)+\(chapter):\(verse)?translation=web"
        guard let encodedUrlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedUrlString) else {
            print("Invalid URL: \(urlString)")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching verse range: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("No data received")
                return
            }
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("Response: \(jsonResponse)")
                }
            } catch {
                print("Error parsing data: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    func fetchAndPasteVerseRange(book: String?, chapter: Int?, startVerse: Int?, endVerse: Int?) {
        guard let book = book, let chapter = chapter, let startVerse = startVerse, let endVerse = endVerse else { return }
        let urlString = "https://bible-api.com/\(book)+\(chapter):\(startVerse)-\(endVerse)?translation=web"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching verse range: \(error)")
                return
            }
            guard let data = data else {
                print("No data received")
                return
            }
            do {
                if let verseData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let verseText = verseData["text"] as? String {
                    DispatchQueue.main.async {
                        self.textDocumentProxy.insertText(verseText + "\(book) \(chapter):\(startVerse)-\(endVerse)")

                    }
                }
            } catch {
                print("Error parsing verse range data: \(error)")
            }
        }.resume()
    }
}
