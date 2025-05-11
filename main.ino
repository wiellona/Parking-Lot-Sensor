// Arduino sketch to interface with assembly code
// This file acts as a bridge to include the assembly code

// Use external assembly code
extern "C" {
  int main(); // From Master.S
  void slave_main(); // From Slave.S
}

void setup() {
  // Initialize Serial for debugging
  Serial.begin(9600);
  Serial.println("Smart Parking System");
  
  // Choose which assembly program to run
  // Uncomment only one of these lines:
  main();        // Run Master code
  // slave_main();  // Run Slave code
}

void loop() {
  // Nothing to do here - assembly code takes over
}