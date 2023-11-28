# HARP
Heart Attack Risk Predictor - predicts the risk of a heart attack in females based on data retrieved from Apple Health and user input.
To calculate the risk of a heart attack HARP uses a Random Forest regressor model trained on data of female participants of The Framingham Heart Study, augmented with synthetic data points for features tracked in Apple Health (such as step count and walking/running distance, menstrual cycle anomalies, and symptoms potentially indicative of heart disease), as well as primary diet. 
Calculated risk is displayed to the user along with recommendations from American Heart Association.
