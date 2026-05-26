//
//  AppStrings.swift
//  MRBooth
//

import Foundation

enum AppStrings {
    // MARK: - App
    static let appName = "MR Booth"
    static let appTagline = "Booth Voter Management"

    // MARK: - Splash
    static let splashLoading = "Checking session…"

    // MARK: - Login
    static let loginTitle = "Welcome"
    static let loginSubtitle = "Sign in with your Google account to manage booth voters"
    static let signInWithGoogle = "Sign in with Google"
    static let loginFooter = "One Gmail account per booth • Internet required"

    // MARK: - Registration
    static let registrationTitle = "Booth Registration"
    static let registrationSubtitle = "Complete once — cannot be changed later"
    static let state = "State"
    static let district = "District"
    static let ward = "Ward"
    static let boothNumber = "Booth Number"
    static let submitRegistration = "Create Booth & Sheet"
    static let registeringBooth = "Requesting Drive access and creating booth…"
    static let registrationNote = "This will create your Google Drive folder and link a \"VotersMRBooth\" sheet. If one already exists in the folder, you can choose to reuse it or create a new sheet."
    static let existingSheetTitle = "Existing Voter Sheet Found"
    static let existingSheetMessage = "A Google Sheet named \"VotersMRBooth\" already exists for this booth. Do you want to reuse it or create a new sheet?"
    static let reuseExistingSheet = "Use Existing Sheet"
    static let createNewSheet = "Create New Sheet"
    static let drivePermissionNote = "You will be asked to allow Google Drive and Sheets access for this account."
    static let selectDistrict = "Select district"
    static let selectWard = "Select ward"
    static let electionLevel = "Election Level"
    static let lokSabha = "Lok Sabha"
    static let assembly = "Assembly"
    static let localBody = "Local Body"
    static let constituency = "Constituency"
    static let selectLokSabhaConstituency = "Select Lok Sabha constituency"
    static let selectAssemblyConstituency = "Select Assembly constituency"
    static let selectLocalBody = "Select local body"
    static let registrationValidationLokSabha = "Select district, Lok Sabha constituency, and booth number"
    static let registrationValidationAssembly = "Select district, Assembly constituency, and booth number"
    static let registrationValidationLocalBody = "Select district, local body, ward, and booth number"
    static let electionLevelLabel = "Level"

    // MARK: - Dashboard
    static let dashboard = "Dashboard"
    static let scanVoterList = "Scan Voter List"
    static let viewVoters = "View Voters"
    static let filters = "Filters"
    static let reports = "Reports"
    static let settings = "Settings"
    static let totalVoters = "Total Voters"
    static let voted = "Voted"
    static let remaining = "Remaining"

    // MARK: - Scan
    static let scanTitle = "Scan Voters"
    static let cameraScan = "Camera Scan"
    static let uploadPDF = "Upload PDF"
    static let uploadImage = "Upload Image"
    static let processingOCR = "Extracting voter data with AI…"
    static let savingToSheet = "Saving to sheet…"
    static let reviewExtracted = "Review Extracted Data"
    static let saveToSheet = "Save to Sheet"
    static let discardScan = "Discard"

    // MARK: - Voter List
    static let voterList = "Voters"
    static let searchVoters = "Search by name or ID"
    static let noVoters = "No voters yet"
    static let noVotersHint = "Scan a voter list to get started"
    static let noMatchingVoters = "No voters match your filters"
    static let noMatchingVotersHint = "Try adjusting filters or search"
    static let totalVoterCount = "Total: %d voters"
    static let showingFilteredCount = "Showing %d"
    static let clearFilters = "Clear"
    static let filterByParty = "Party"
    static let filterByVoting = "Status"
    static let markVoted = "Mark Voted"

    // MARK: - Filter
    static let filterTitle = "Filters"
    static let partyStatus = "Party Support"
    static let votingStatus = "Voting Status"
    static let applyFilters = "Apply Filters"
    static let resetFilters = "Reset"

    // MARK: - Edit
    static let editVoter = "Edit Voter"
    static let saveChanges = "Save Changes"
    static let deleteConfirmTitle = "Delete Voter?"
    static let deleteConfirmMessage = "This will permanently remove the voter from your sheet."
    static let cancel = "Cancel"
    static let delete = "Delete"

    // MARK: - Reports
    static let reportsTitle = "Reports"
    static let partyDistribution = "Party Distribution"
    static let votingProgress = "Voting Progress"

    // MARK: - Settings
    static let settingsTitle = "Settings"
    static let boothInfo = "Booth Information"
    static let syncData = "Sync Data"
    static let logout = "Logout"
    static let logoutConfirm = "Sign out of this booth?"
    static let clearData = "Clear All Voter Data"
    static let clearDataConfirmTitle = "Clear all voter data?"
    static let clearDataConfirmMessage =
        "This permanently removes every voter row from your Google Sheet and clears data on this device. Booth registration and your Google account stay unchanged."
    static let clearDataConfirmAction = "Clear All Data"
    static let lastSynced = "Last synced"
    static let neverSynced = "Never"
    static let geminiAPIKeySection = "AI Extraction (Gemini)"
    static let geminiAPIKeyPlaceholder = "Paste API key from Google AI Studio"
    static let geminiAPIKeyHelp = "Get a key at aistudio.google.com/apikey. Required for scan and PDF upload."
    static let saveGeminiAPIKey = "Save API Key"
    static let geminiAPIKeySaved = "API key saved"
    static let geminiAPIKeyMissing = "Add your Gemini API key in Settings before scanning."

    // MARK: - Fields
    static let serialNumber = "Serial No."
    static let name = "Name"
    static let address = "Address"
    static let voterID = "Voter ID / EPIC / SEC ID"
    static let age = "Age"
    static let partyStatusLabel = "Party Status"
    static let votingStatusLabel = "Voting Status"

    // MARK: - Errors
    static let errorTitle = "Something went wrong"
    static let ok = "OK"
    static let offlineMessage = "Internet connection required"
    static let duplicateVoter = "Duplicate voter ID detected"
    static let missingFields = "Some fields are missing"
}
