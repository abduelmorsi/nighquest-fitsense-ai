# FitSense AI — Intelligent Fitness Tracker 🏃‍♂️💨

**FitSense AI** is an end-to-end, AI-powered fitness tracking pipeline built entirely in MATLAB. It leverages smartphone sensor data (via MATLAB Mobile) to classify physical activities using deep learning, estimate calories, count steps, and visualize workout performance through a premium App Designer dashboard.

This project was built for the **BEST Istanbul Yıldız Hackathon** (MathWorks track).

---

## 🚀 Features

*   **Advanced Signal Processing**: 4th-order Butterworth bandpass filtering and zero-phase distortion (`filtfilt`) to remove gravity and electronic noise.
*   **Deep Learning Classifier**: A Bidirectional LSTM (BiLSTM) network that captures the temporal rhythm of human movement, achieving high accuracy across 6 activities.
*   **Classic ML Baseline**: Comparative analysis against SVM, KNN, Decision Trees, and Random Forest.
*   **Workout DNA Fingerprint**: A custom polar radar chart visualization that creates a unique "visual fingerprint" for every workout.
*   **Premium Dashboard**: A dark-themed, tabbed App Designer GUI for interactive data analysis.

---

## 📂 Repository Structure

To keep the repository clean and professional, we have organized the files as follows:

```text
├── FitSenseApp.m              # Main App Designer GUI Application
├── RunEverything.m            # Master script to train models & run analysis
├── FitSenseAI_Main.m          # Core pipeline script (alternative to RunEverything)
├── generateExtraPlots.m       # Utility to generate presentation plots
│
├── [Helper Functions]
├── preprocessSensorData.m     # Signal processing and filtering
├── trainLSTMClassifier.m      # BiLSTM training logic
├── trainClassicML.m           # Traditional ML model training
├── detectSteps.m              # Peak detection for step counting
├── calculateCalories.m        # MET-based calorie estimation
├── createWorkoutDNA.m         # Radar chart generation
├── plotFitnessDashboard.m     # 6-panel static visualization
├── plotModelComparison.m      # Accuracy comparison bar chart
├── haversine.m                # GPS distance calculation
├── extractFeatures.m          # Time/Frequency domain feature extraction
│
├── [Data & Assets]
├── *.mat                      # Your collected sensor data files
├── presentation.html          # Interactive HTML presentation deck
└── *.png                      # Presentation screenshots and visuals
```

---

## 🛠️ Installation & Requirements

To run this project locally, you need **MATLAB (R2023a or newer)** with the following toolboxes installed:

1.  **Deep Learning Toolbox**
2.  **Statistics and Machine Learning Toolbox**
3.  **Signal Processing Toolbox**

---

## 🏁 How to Run

### 1. Run the Full Pipeline
Open MATLAB, navigate to this folder, and run:
```matlab
RunEverything
```
This will load the data, train the models, compare accuracies, and pop up the dashboard and Workout DNA plots.

### 2. Run the Interactive Dashboard
To launch the App Designer UI directly:
```matlab
FitSenseApp
```
Click **Load Data** to select a `.mat` file, and **Run Analysis** to see the AI in action!

### 3. View the Presentation
Open `presentation.html` in any web browser to view the project pitch deck. Use the left/right arrow keys to navigate.

---

## 📊 Results

*   **LSTM Accuracy**: ~95.7%
*   **Best Classic Model**: Random Forest (~94.4%)
*   **Activities Classified**: Sitting, Walking, Fast Walking, Jogging, Running, Stairs.

---
*Built with ❤️ by NighQuest.*
