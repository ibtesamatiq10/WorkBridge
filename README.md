# Agentic AI Service Orchestrator

This project simulates an Agentic AI System for the informal economy, automating the end-to-end lifecycle of a service request using the **Google Antigravity** core platform.

## Mandatory Requirement: Google Antigravity
This application strictly uses the **Google Antigravity** platform to orchestrate the entire agent workflow:
- **Orchestrate agent workflows**: The `AntigravityPlatformService` serves as the central brain orchestrating the lifecycle (Intent -> Discovery -> Reasoning -> Booking -> Notification).
- **Manage multi-step reasoning**: The agent evaluates multiple variables (provider proximity, ratings, and schedule) to deduce the best match. This is explicitly demonstrated in the "Agent Reasoning Logs" panel in the UI.
- **Integrate tools (Maps, Search, APIs)**: The workflow simulates integration with external tools (Google Maps for coordinate resolution, Search APIs for local discovery). 
- **Execute actions (booking, notifications, etc.)**: The platform simulates transactions against a Booking API to generate confirmation IDs and triggers automated notifications as follow-ups.

## Architecture
The app follows **Clean Architecture**:
- **Domain Layer**: Contains the core entities (`ServiceRequest`, `Provider`, `Booking`, `WorkflowLog`).
- **Data Layer**: Contains mock datasets and the `AntigravityPlatformService` (powered by Gemini) for reasoning and natural language processing.
- **Application Layer**: Uses `flutter_riverpod` (`Notifier`) to manage state and drive the multi-step execution.
- **Presentation Layer**: A responsive Flutter UI containing a Chat Input for requests and a live Log Panel for observing the Antigravity workflow.

## How to Run
1. Create a `.env` file in the root directory.
2. Add your Gemini API key: `GEMINI_API_KEY=`ADD_GEMNI_API_KEY_HERE`
3. Add you Map API key: `ADD_MAP_API_KEY_HERE`
4. Run the app: `flutter run`
5. Try natural language inputs in English, Urdu, or Roman Urdu (e.g., "Mujhe kal subah G-13 Islamabad mein AC technician chahiye").

## Assumptions & Limitations
- The "Google Antigravity" core platform utilizes the Google Gemini API behind the scenes to perform the AI actions.
- Local providers are mocked, simulating a search radius matching real-world behavior.
- Bookings and notifications are simulated with deliberate delays to represent external API calls, updating the UI accordingly.
