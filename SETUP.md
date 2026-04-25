# Konfiguracja projektu WaterTracker w Xcode

Ten dokument opisuje krok po kroku, jak skonfigurować projekt Xcode dla aplikacji WaterTracker z dwoma targetami (App + Widget Extension), App Groups oraz zależnością SwiftCheck.

---

## Wymagania wstępne

- **Xcode 15.0+**
- **iOS 17.0+** (cel wdrożenia)
- **Swift 5.9+**
- Darmowe konto Apple Developer (wystarczy do sideload)

---

## 1. Tworzenie projektu Xcode z dwoma targetami

### 1.1 Utwórz główny projekt

1. Otwórz Xcode → **File → New → Project…**
2. Wybierz szablon **iOS → App**
3. Wypełnij dane:
   - **Product Name:** `WaterTracker`
   - **Bundle Identifier:** `com.yourname.watertracker`
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Minimum Deployments:** iOS 17.0
4. Kliknij **Next** i wybierz lokalizację projektu (katalog główny repozytorium)

### 1.2 Dodaj target Widget Extension

1. W nawigatorze projektu zaznacz projekt `WaterTracker`
2. Kliknij przycisk **+** na dole listy targetów (lub **File → New → Target…**)
3. Wybierz **iOS → Widget Extension**
4. Wypełnij dane:
   - **Product Name:** `WaterTrackerWidget`
   - **Bundle Identifier:** `com.yourname.watertracker.widget`
   - **Include Configuration Intent:** NIE (odznacz)
5. Kliknij **Finish** — Xcode zapyta czy aktywować schemat widgetu; kliknij **Activate**

---

## 2. Konfiguracja App Groups

App Groups umożliwiają współdzielenie danych (`UserDefaults`) między aplikacją a widgetem.

### 2.1 Dodaj capability do targetu App

1. W nawigatorze projektu zaznacz target **WaterTracker**
2. Przejdź do zakładki **Signing & Capabilities**
3. Kliknij **+ Capability** i wybierz **App Groups**
4. Kliknij **+** pod listą grup i wpisz identyfikator:
   ```
   group.com.yourname.watertracker
   ```
5. Xcode automatycznie wygeneruje plik `WaterTracker.entitlements` — zastąp jego zawartość plikiem z katalogu `WaterTracker/WaterTracker.entitlements` z tego repozytorium

### 2.2 Dodaj capability do targetu Widget Extension

1. Zaznacz target **WaterTrackerWidget**
2. Przejdź do zakładki **Signing & Capabilities**
3. Kliknij **+ Capability** i wybierz **App Groups**
4. Kliknij **+** i wpisz **ten sam** identyfikator:
   ```
   group.com.yourname.watertracker
   ```
5. Zastąp wygenerowany plik `WaterTrackerWidget.entitlements` plikiem z katalogu `WaterTrackerWidget/` z tego repozytorium

> **Ważne dla sideload:** Przy darmowym certyfikacie Apple identyfikator grupy musi zawierać Twój Team ID. Podmień `yourname` na swój Team ID (np. `group.AB12CD34EF.watertracker`). AltStore i Sideloadly automatycznie podpisują entitlements przy instalacji.

---

## 3. Konfiguracja target membership dla plików Shared/

Pliki w katalogu `Shared/` (`AppGroupStore.swift`, `WaterLogic.swift`) muszą być skompilowane w **obu** targetach.

### 3.1 Dodaj pliki Shared/ do projektu

1. W nawigatorze projektu kliknij prawym przyciskiem na grupę `WaterTracker`
2. Wybierz **Add Files to "WaterTracker"…**
3. Przejdź do katalogu `Shared/` i zaznacz oba pliki Swift
4. W sekcji **Add to targets** zaznacz **oba** targety:
   - ✅ `WaterTracker`
   - ✅ `WaterTrackerWidget`
5. Kliknij **Add**

### 3.2 Weryfikacja target membership

Dla każdego pliku w `Shared/`:
1. Zaznacz plik w nawigatorze
2. Otwórz **File Inspector** (prawy panel, ikona dokumentu)
3. W sekcji **Target Membership** upewnij się, że zaznaczone są oba targety

---

## 4. Dodanie SwiftCheck jako zależność SPM

SwiftCheck jest używany wyłącznie w targecie testowym `WaterTrackerTests`.

### 4.1 Dodaj pakiet do projektu

1. W Xcode wybierz **File → Add Package Dependencies…**
2. W polu wyszukiwania wklej URL:
   ```
   https://github.com/typelift/SwiftCheck.git
   ```
3. W sekcji **Dependency Rule** wybierz **Exact Version** i wpisz `0.12.0`
4. Kliknij **Add Package**
5. W oknie wyboru targetów zaznacz **wyłącznie** `WaterTrackerTests`
6. Kliknij **Add Package**

### 4.2 Weryfikacja

W nawigatorze projektu w sekcji **Package Dependencies** powinien pojawić się `SwiftCheck 0.12.0`.

---

## 5. Konfiguracja Info.plist

Projekt używa plików `Info.plist` z tego repozytorium:

- `WaterTracker/Info.plist` — dla targetu App
- `WaterTrackerWidget/Info.plist` — dla targetu Widget Extension

Jeśli Xcode wygenerował własne pliki `Info.plist`, zastąp ich zawartość plikami z repozytorium.

W ustawieniach każdego targetu (**Build Settings → Info.plist File**) upewnij się, że ścieżka wskazuje na właściwy plik.

---

## 6. Struktura katalogów

Po konfiguracji projekt powinien mieć następującą strukturę:

```
WaterTracker.xcodeproj
├── WaterTracker/
│   ├── WaterTrackerApp.swift        # @main, punkt wejścia aplikacji
│   ├── MainView.swift               # Ekran główny
│   ├── SettingsView.swift           # Ekran ustawień
│   ├── WaterStore.swift             # ViewModel (ObservableObject)
│   ├── WaterTracker.entitlements    # App Groups capability
│   ├── Info.plist
│   └── Assets.xcassets
│
├── WaterTrackerWidget/
│   ├── WaterTrackerWidget.swift     # Widget + Provider + Entry
│   ├── WaterTrackerView.swift       # Widok widgetu
│   ├── AddWaterIntent.swift         # AppIntent dla przycisku "+"
│   ├── WaterTrackerWidget.entitlements
│   └── Info.plist
│
├── Shared/                          # Współdzielone między App i Widget
│   ├── AppGroupStore.swift          # Warstwa danych (UserDefaults + App Group)
│   └── WaterLogic.swift             # Czyste funkcje (walidacja, postęp, odejmowanie)
│
├── WaterTrackerTests/               # Testy jednostkowe i właściwości
│   ├── WaterTrackerUnitTests.swift
│   └── WaterTrackerPropertyTests.swift
│
├── Package.swift                    # SPM — zależność SwiftCheck dla testów
├── SETUP.md                         # Ten plik
└── README.md                        # Instrukcja instalacji przez sideload
```

---

## 7. Weryfikacja konfiguracji

Po wykonaniu powyższych kroków sprawdź:

- [ ] Oba targety mają capability **App Groups** z identycznym identyfikatorem
- [ ] Pliki `Shared/AppGroupStore.swift` i `Shared/WaterLogic.swift` mają zaznaczone oba targety w **Target Membership**
- [ ] `SwiftCheck 0.12.0` jest dodany jako zależność SPM tylko do `WaterTrackerTests`
- [ ] Projekt buduje się bez błędów dla obu targetów (**Product → Build** lub `⌘B`)
- [ ] Testy przechodzą (**Product → Test** lub `⌘U`)

---

## 8. Podmiana identyfikatora App Group dla sideload

Przy instalacji przez AltStore lub Sideloadly z darmowym certyfikatem:

1. Znajdź swój **Team ID** w [Apple Developer Portal](https://developer.apple.com/account) lub w Xcode → **Preferences → Accounts**
2. Zamień `com.yourname` na `TWÓJ_TEAM_ID` we wszystkich miejscach:
   - `WaterTracker/WaterTracker.entitlements`
   - `WaterTrackerWidget/WaterTrackerWidget.entitlements`
   - `Shared/AppGroupStore.swift` (stała `appGroupID`)
   - `WaterTracker/Info.plist` (Bundle Identifier)
   - `WaterTrackerWidget/Info.plist` (Bundle Identifier)
3. W Xcode zaktualizuj identyfikatory App Group w zakładce **Signing & Capabilities** obu targetów

> AltStore i Sideloadly automatycznie podpisują entitlements przy instalacji — nie musisz mieć płatnego konta deweloperskiego.
