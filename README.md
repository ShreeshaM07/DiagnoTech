# DiagnoTech

Cutting-Edge Medical Image Classifier for Disease Inference: Revolutionizing Healthcare through AI.
A Windows application built using Flutter which diagnoses diseases based on an ML image classification model .

## Description

Our medical AI image classifier provides a robust and efficient solution for the early detection and inference of diseases using MRI and fundus images. This innovative technology has been seamlessly integrated into an accessible and user-friendly desktop app.

## Key Features


  ### Multi Modality support:
  The app accommodates a wide range of medical imaging modalities, including MRI and fundus images, making it versatile and adaptable for different clinical scenarios.
  ### Disease Inference:
Leveraging machine learning techniques, our classifier is proficient in identifying various diseases and conditions such as tumors, retinal disorders, and more.
  ### Real-time Analysis:
  Users can swiftly upload medical images, and within seconds, receive a detailed analysis report, including potential diagnoses, confidence levels, and relevant medical insights.
  ### User-Friendly Interface:
Designed with both healthcare professionals and patients in mind, the app boasts an intuitive, easy-to-navigate interface, ensuring accessibility to a wide audience.
## Working

`Image Selection`: Upon launching the app, users are presented with a clear and intuitive interface made using flutter. They are prompted to choose between MRI or fundus images, each accessible through dedicated screens. This choice flexibility ensures that the app caters to diverse medical imaging needs.\
`Image Submission`: After selecting the image type (MRI or fundus), users can upload their medical images directly from their device's gallery. The app simplifies the process, making it accessible to users of all technical backgrounds.\
`Flask API Integration`: Behind the scenes, our Flask API serves as the bridge between the app and the machine learning model. When an image is submitted, the app communicates with the Flask API, sending the image for analysis.\
`Machine Learning Inference`: The Flask API routes the received image to the machine learning model, which has been pre-trained to recognize diseases and conditions specific to MRI or fundus images. The model performs a comprehensive analysis of the image, identifying potential diseases and anomalies.\
`Inference Report`: The app then presents the user with an inference report. This report includes the disease or condition identified, along with confidence levels to provide an indication of the model's certainty in its diagnosis. Users can review this information and take appropriate actions, such as seeking medical advice or further testing.\


