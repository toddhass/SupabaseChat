# Setting Up the SupabaseChat Project in Xcode

This guide will walk you through downloading the project files and setting them up in Xcode.

## Step 1: Download the Project Files

In Replit, you can download all the files by:

1. Click on the three-dot menu in the top-right corner of the Replit interface
2. Select "Download as ZIP"
3. Save the ZIP file to your computer
4. Extract the ZIP to a folder of your choice

## Step 2: Create a New Xcode Project

1. Open Xcode
2. Create a new SwiftUI project:
   - Select "File > New > Project"
   - Choose "iOS App" (or "macOS App" if targeting Mac)
   - Name your project "SupabaseChat"
   - Select "SwiftUI" for Interface
   - Select "Swift" for Language
   - Choose a location to save your project

## Step 3: Add Project Files to Xcode

Copy these key files from the extracted Replit project to your Xcode project:

1. **Swift Files:**
   - All files in the `SupabaseChat` folder
   - `supabase_auth_demo.swift`
   - `supabase_chat_api.swift`
   - `user_status.swift`

2. **Documentation and Setup:**
   - `create.sql`
   - `SUPABASE_SETUP.md`

## Step 4: Set Up the Project Structure in Xcode

1. Create the same folder structure as in the Replit project:
   - Models
   - Services
   - Utilities
   - Views

2. Organize the files into these folders according to their location in the Replit project

## Step 5: Set Up Supabase Credentials

There are two ways to set up your Supabase credentials:

### Option 1: Use Environment Variables (recommended for development)
1. Edit your scheme in Xcode:
   - Select "Product > Scheme > Edit Scheme"
   - Select "Run" from the left sidebar
   - Go to the "Arguments" tab
   - Under "Environment Variables", add:
     - SUPABASE_URL: Your Supabase project URL
     - SUPABASE_KEY: Your Supabase public API key

### Option 2: Hardcode (only for testing, not recommended for production)
1. Create a `Config.swift` file with the following content:
```swift
import Foundation

struct Config {
    static let supabaseUrl = "YOUR_SUPABASE_URL"
    static let supabaseKey = "YOUR_SUPABASE_KEY"
}
```

2. Update all references to environment variables to use this Config struct instead.

## Step 6: Set Up Supabase Database

1. Follow the instructions in `SUPABASE_SETUP.md` to set up your Supabase database
2. Run the SQL script in `create.sql` in your Supabase SQL editor

## Step 7: Install Supabase Swift SDK

If you want to use the full Supabase Swift SDK (recommended for a production app):

1. Add the Supabase Swift SDK to your project using Swift Package Manager:
   - In Xcode, select "File > Add Package Dependencies..."
   - Enter: `https://github.com/supabase-community/supabase-swift`
   - Click "Add Package"

2. Alternatively, you can use our direct HTTP implementation in `supabase_chat_api.swift` and `supabase_auth_demo.swift`

## Step 8: Run the Project

1. Select your target device or simulator
2. Click the Run button (or press ⌘R)

## Troubleshooting

- If you encounter build errors, check that all required files are included and the folder structure is correct
- If authentication fails, verify your Supabase credentials are correctly set up
- If database operations fail, ensure you've run the SQL script in your Supabase project

## Additional Notes

- The demos in `supabase_auth_demo.swift` and `supabase_chat_api.swift` are designed to run in a console environment. You'll need to adapt them for use in your SwiftUI app
- The `SupabaseChat` folder contains a more complete implementation designed for a SwiftUI app

For any questions or issues, refer to the Supabase Swift SDK documentation or the Swift standard library documentation.