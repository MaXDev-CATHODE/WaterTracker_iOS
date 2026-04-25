# WaterTracker iOS

Aplikacja iOS do śledzenia dziennego spożycia wody. Składa się z aplikacji głównej (SwiftUI) oraz widgetu na ekran główny (WidgetKit) z przyciskiem „+" do szybkiego dodawania porcji jednym tapnięciem. Dane są współdzielone między aplikacją a widgetem przez App Groups. Aplikacja jest dystrybuowana przez sideload — bez publikacji w App Store.

---

## Wymagania wstępne

- **AltStore 1.7+** lub **Sideloadly** (najnowsza wersja) — [altstore.io](https://altstore.io) / [sideloadly.io](https://sideloadly.io)
- **Darmowe konto Apple Developer** (wystarczy zwykłe Apple ID)
- **Xcode 15.0+** — do zbudowania pliku `.ipa`
- **iOS 17.0+** na urządzeniu docelowym

---

## Budowanie pliku .ipa w Xcode

1. Otwórz projekt `WaterTracker.xcodeproj` w Xcode
2. Wybierz schemat **WaterTracker** (nie WaterTrackerWidget) i jako urządzenie docelowe wybierz **Any iOS Device (arm64)**
3. Przejdź do **Product → Archive** i poczekaj na zakończenie archiwizacji
4. Po zakończeniu otworzy się okno **Organizer** — kliknij **Distribute App**
5. Wybierz metodę dystrybucji:
   - **Ad Hoc** — instalacja na konkretnych urządzeniach (wymaga dodania UDID w Apple Developer Portal)
   - **Development** — szybsza opcja do testów na własnym urządzeniu
6. Wybierz certyfikat podpisywania — przy darmowym koncie Xcode automatycznie użyje 7-dniowego certyfikatu deweloperskiego
7. Kliknij **Export** i wskaż folder docelowy
8. Wynikowy plik `.ipa` znajdziesz w wybranym folderze (np. `WaterTracker.ipa`)

> **Uwaga:** Przy darmowym certyfikacie możesz mieć maksymalnie 3 aktywne aplikacje sideloadowane jednocześnie (ograniczenie Apple).

---

## Instalacja przez AltStore

1. Zainstaluj AltStore na komputerze i urządzeniu iOS zgodnie z instrukcją na [altstore.io](https://altstore.io)
2. Upewnij się, że AltServer działa na komputerze i urządzenie jest podłączone do tej samej sieci Wi-Fi (lub przez USB)
3. Otwórz AltStore na urządzeniu iOS
4. Przejdź do zakładki **My Apps** i kliknij przycisk **+** w lewym górnym rogu
5. Wybierz **Sideload an IPA** i wskaż plik `WaterTracker.ipa` (możesz go przesłać przez AirDrop, iCloud Drive lub inne)
6. Poczekaj na zakończenie instalacji
7. Zaufaj certyfikatowi dewelopera:
   - Przejdź do **Ustawienia → Ogólne → Zarządzanie urządzeniem (VPN i zarządzanie urządzeniem)**
   - Znajdź swoje Apple ID i kliknij **Zaufaj „Twoje Apple ID"**
   - Potwierdź kliknięciem **Zaufaj**

---

## Instalacja przez Sideloadly

1. Pobierz i zainstaluj Sideloadly ze strony [sideloadly.io](https://sideloadly.io) (dostępny na macOS i Windows)
2. Podłącz iPhone do komputera kablem USB
3. Odblokuj urządzenie i potwierdź zaufanie komputerowi jeśli pojawi się monit
4. Przeciągnij plik `WaterTracker.ipa` do okna Sideloadly (lub kliknij ikonę IPA i wskaż plik)
5. W polu **Apple Account** wpisz swój Apple ID
6. Kliknij przycisk **Start** — Sideloadly poprosi o hasło Apple ID
7. Poczekaj na zakończenie instalacji (pasek postępu w oknie Sideloadly)
8. Zaufaj certyfikatowi dewelopera:
   - Przejdź do **Ustawienia → Ogólne → Zarządzanie urządzeniem (VPN i zarządzanie urządzeniem)**
   - Znajdź swoje Apple ID i kliknij **Zaufaj „Twoje Apple ID"**
   - Potwierdź kliknięciem **Zaufaj**

---

## Odświeżanie certyfikatu co 7 dni

Darmowy certyfikat Apple wygasa po **7 dniach** — aplikacja przestanie się uruchamiać i trzeba ją ponownie podpisać.

**AltStore — odświeżanie automatyczne:**
- AltStore odświeża certyfikaty automatycznie w tle, gdy AltServer działa na komputerze i urządzenie jest w tej samej sieci Wi-Fi
- Możesz też odświeżyć ręcznie: zakładka **My Apps** → przytrzymaj ikonę WaterTracker → **Refresh**
- AltStore wyśle powiadomienie gdy certyfikat będzie bliski wygaśnięcia

**Sideloadly — odświeżanie ręczne:**
- Powtórz całą procedurę instalacji (kroki 3–8 powyżej) z tym samym plikiem `.ipa`
- Sideloadly nadpisze poprzednią instalację zachowując dane aplikacji

---

## Konfiguracja App Group ID (podmiana `com.yourname`)

Przy darmowym certyfikacie identyfikator App Group musi zawierać Twój **Team ID** (10-znakowy kod alfanumeryczny przypisany do Twojego Apple ID).

### Jak znaleźć Team ID

- **Apple Developer Portal:** zaloguj się na [developer.apple.com/account](https://developer.apple.com/account) → sekcja **Membership details** → pole **Team ID**
- **Xcode:** Preferences (lub Settings) → **Accounts** → wybierz swoje Apple ID → kliknij **Manage Certificates** — Team ID widoczny obok nazwy konta

### Pliki do zmiany

Zamień `yourname` na swój Team ID we wszystkich poniższych miejscach:

| Plik | Wartość do zmiany |
|------|-------------------|
| `WaterTracker/WaterTracker.entitlements` | `group.com.yourname.watertracker` |
| `WaterTrackerWidget/WaterTrackerWidget.entitlements` | `group.com.yourname.watertracker` |
| `Shared/AppGroupStore.swift` | stała `appGroupID` |
| `WaterTracker/Info.plist` | `CFBundleIdentifier` |
| `WaterTrackerWidget/Info.plist` | `CFBundleIdentifier` |

**Przykład** — jeśli Twój Team ID to `AB12CD34EF`:

```
group.com.yourname.watertracker  →  group.AB12CD34EF.watertracker
com.yourname.watertracker        →  com.AB12CD34EF.watertracker
com.yourname.watertracker.widget →  com.AB12CD34EF.watertracker.widget
```

Po zmianie zaktualizuj też identyfikatory App Group w Xcode:
1. Zaznacz target **WaterTracker** → zakładka **Signing & Capabilities**
2. W sekcji **App Groups** usuń stary identyfikator i dodaj nowy
3. Powtórz dla targetu **WaterTrackerWidget**

> AltStore i Sideloadly automatycznie podpisują entitlements przy instalacji — nie musisz mieć płatnego konta deweloperskiego.

---

## Struktura projektu

```
WaterTracker.xcodeproj
├── WaterTracker/               # Aplikacja główna (SwiftUI)
│   ├── WaterTrackerApp.swift   # Punkt wejścia (@main)
│   ├── MainView.swift          # Ekran główny — postęp i dodawanie porcji
│   ├── SettingsView.swift      # Ekran ustawień — cel dzienny i domyślna porcja
│   ├── WaterStore.swift        # ViewModel (ObservableObject)
│   ├── WaterTracker.entitlements
│   └── Info.plist
│
├── WaterTrackerWidget/         # Widget na ekran główny (WidgetKit)
│   ├── WaterTrackerWidget.swift  # Provider, Entry, konfiguracja widgetu
│   ├── WaterTrackerView.swift    # Widok widgetu (systemSmall, systemMedium)
│   ├── AddWaterIntent.swift      # AppIntent dla przycisku „+"
│   ├── WaterTrackerWidget.entitlements
│   └── Info.plist
│
├── Shared/                     # Kod współdzielony między App i Widget
│   ├── AppGroupStore.swift     # Warstwa danych (UserDefaults + App Group)
│   └── WaterLogic.swift        # Czyste funkcje (walidacja, postęp, odejmowanie)
│
├── WaterTrackerTests/          # Testy jednostkowe i właściwości (SwiftCheck)
│   ├── WaterTrackerUnitTests.swift
│   ├── WaterStoreTests.swift
│   ├── WaterLogicPropertyTests.swift
│   └── AppGroupStorePropertyTests.swift
│
├── Package.swift               # Zależność SwiftCheck dla testów
├── SETUP.md                    # Instrukcja konfiguracji projektu w Xcode
└── README.md                   # Ten plik
```

---

## Budowanie bez macOS — GitHub Actions (darmowe)

Jeśli nie masz macOS, możesz zbudować `.ipa` za darmo przez GitHub Actions (2000 minut/miesiąc gratis).

### Kroki

1. **Wrzuć projekt na GitHub:**
   ```
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/TWOJ_LOGIN/watertracker-ios.git
   git push -u origin main
   ```

2. **GitHub automatycznie uruchomi build** po każdym `push` do `main`

3. **Pobierz gotowy `.ipa`:**
   - Wejdź na GitHub → zakładka **Actions**
   - Kliknij ostatni run „Build WaterTracker IPA"
   - Na dole strony w sekcji **Artifacts** kliknij **WaterTracker-unsigned-ipa**
   - Rozpakuj pobrany `.zip` — w środku jest `WaterTracker-unsigned.ipa`

4. **Zainstaluj przez Sideloadly** (na Windows):
   - Otwórz Sideloadly, przeciągnij `WaterTracker-unsigned.ipa`
   - Zaloguj się Apple ID → kliknij **Start**
   - Sideloadly podpisze `.ipa` Twoim certyfikatem podczas instalacji

5. **Podmień `com.yourname`** przed pierwszym buildem (patrz sekcja wyżej) — edytuj pliki bezpośrednio w repozytorium lub lokalnie przed `git push`

> **Uwaga:** Zbudowane `.ipa` jest niepodpisane — Sideloadly podpisuje je automatycznie podczas instalacji używając Twojego Apple ID.

---

## Dodatkowe informacje

Szczegółowa instrukcja konfiguracji projektu Xcode (tworzenie targetów, App Groups, dodawanie SwiftCheck) znajduje się w pliku [SETUP.md](SETUP.md).
