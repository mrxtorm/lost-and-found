import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/item_provider.dart';

class ReportItemScreen extends StatefulWidget {
  const ReportItemScreen({super.key});

  @override
  State<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends State<ReportItemScreen> {
  String selectedType = "Lost";

  final TextEditingController itemNameController =
  TextEditingController();

  final TextEditingController descriptionController =
  TextEditingController();

  final TextEditingController verificationQuestionController =
  TextEditingController();

  String? selectedCategory;
  String? selectedLocation;
  DateTime? selectedDate;

  File? selectedImage;

  final ImagePicker imagePicker = ImagePicker();
  bool isSubmitting = false;

  final List<String> categories = [
    "Electronics",
    "Wallet",
    "ID",
    "Keys",
    "Books",
    "Others",
  ];

  final List<String> locations = [
    "Library",
    "Classroom",
    "Laboratory",
    "Cafeteria",
    "Gymnasium",
    "Main Building",
    "Other",
  ];

  @override
  void dispose() {
    itemNameController.dispose();
    descriptionController.dispose();
    verificationQuestionController.dispose();
    super.dispose();
  }

  // =========================
  // SELECT PHOTO
  // =========================

  Future<void> selectPhoto() async {
    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          selectedImage = File(image.path);
        });
      }
    } catch (e) {
      showMessage("Unable to select photo.");
    }
  }

  // =========================
  // REMOVE PHOTO
  // =========================

  void removePhoto() {
    setState(() {
      selectedImage = null;
    });
  }

  // =========================
  // SELECT DATE
  // =========================

  Future<void> selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  // =========================
  // FORMAT DATE
  // =========================

  String get formattedDate {
    if (selectedDate == null) {
      return "Select date";
    }

    return "${selectedDate!.month}/"
        "${selectedDate!.day}/"
        "${selectedDate!.year}";
  }

  // =========================
  // SUBMIT
  // =========================

  Future<void> submitReport() async {
    if (itemNameController.text.trim().isEmpty) {
      showMessage("Please enter the item name.");
      return;
    }

    if (selectedCategory == null) {
      showMessage("Please select a category.");
      return;
    }

    if (descriptionController.text.trim().isEmpty) {
      showMessage("Please enter a description.");
      return;
    }

    if (selectedDate == null) {
      showMessage("Please select the date.");
      return;
    }

    if (selectedLocation == null) {
      showMessage("Please select a location.");
      return;
    }

    if (selectedImage == null) {
      showMessage("Please add a photo.");
      return;
    }

    if (selectedType == "Found" &&
        verificationQuestionController.text.trim().isEmpty) {
      showMessage("Please enter a verification question.");
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await context.read<ItemProvider>().reportItem(
        title: itemNameController.text.trim(),
        description: descriptionController.text.trim(),
        category: selectedCategory!,
        location: selectedLocation!,
        date: formattedDate,
        status: selectedType,
        imageFile: selectedImage,
        verificationQuestion: selectedType == "Found"
            ? verificationQuestionController.text.trim()
            : null,
      );

      if (!mounted) return;
      showMessage("Report submitted successfully.");
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showMessage("Failed to submit report: $e");
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  // =========================
  // MESSAGE
  // =========================

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          "Report Item",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // =========================
            // REPORT TYPE
            // =========================

            const Text(
              "What are you reporting?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [

                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedType = "Lost";
                      });
                    },

                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),

                      decoration: BoxDecoration(
                        color: selectedType == "Lost"
                            ? Colors.red
                            : Colors.white,

                        borderRadius: BorderRadius.circular(12),

                        border: Border.all(
                          color: selectedType == "Lost"
                              ? Colors.red
                              : Colors.grey.shade300,
                        ),
                      ),

                      child: Column(
                        children: [

                          Icon(
                            Icons.report_problem,
                            color: selectedType == "Lost"
                                ? Colors.white
                                : Colors.red,
                            size: 30,
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "Lost Item",
                            style: TextStyle(
                              color: selectedType == "Lost"
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedType = "Found";
                      });
                    },

                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),

                      decoration: BoxDecoration(
                        color: selectedType == "Found"
                            ? Colors.green
                            : Colors.white,

                        borderRadius: BorderRadius.circular(12),

                        border: Border.all(
                          color: selectedType == "Found"
                              ? Colors.green
                              : Colors.grey.shade300,
                        ),
                      ),

                      child: Column(
                        children: [

                          Icon(
                            Icons.check_circle,
                            color: selectedType == "Found"
                                ? Colors.white
                                : Colors.green,
                            size: 30,
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "Found Item",
                            style: TextStyle(
                              color: selectedType == "Found"
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // =========================
            // ITEM NAME
            // =========================

            const Text(
              "Item Name",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: itemNameController,

              decoration: InputDecoration(
                hintText: "Enter item name",

                prefixIcon: const Icon(
                  Icons.inventory_2_outlined,
                ),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // =========================
            // CATEGORY
            // =========================

            const Text(
              "Category",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: selectedCategory,

              decoration: InputDecoration(
                hintText: "Select category",

                prefixIcon: const Icon(
                  Icons.category_outlined,
                ),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),

              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),

              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 20),

            // =========================
            // DESCRIPTION
            // =========================

            const Text(
              "Description",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: descriptionController,

              maxLines: 5,

              decoration: InputDecoration(
                hintText: "Describe the item...",

                alignLabelWithHint: true,

                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 80),
                  child: Icon(
                    Icons.description_outlined,
                  ),
                ),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // =========================
            // DATE
            // =========================

            const Text(
              "Date",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            InkWell(
              onTap: selectDate,

              borderRadius: BorderRadius.circular(12),

              child: Container(
                width: double.infinity,

                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 17,
                ),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Row(
                  children: [

                    const Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.blue,
                    ),

                    const SizedBox(width: 12),

                    Text(
                      formattedDate,

                      style: TextStyle(
                        fontSize: 16,

                        color: selectedDate == null
                            ? Colors.grey.shade600
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // =========================
            // LOCATION
            // =========================

            const Text(
              "Location",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: selectedLocation,

              decoration: InputDecoration(
                hintText: "Select location",

                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                ),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),

              items: locations.map((location) {
                return DropdownMenuItem(
                  value: location,
                  child: Text(location),
                );
              }).toList(),

              onChanged: (value) {
                setState(() {
                  selectedLocation = value;
                });
              },
            ),

            const SizedBox(height: 20),

            // =========================
            // PHOTO
            // =========================

            const Text(
              "Item Photo",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            if (selectedImage == null)

            // ADD PHOTO BOX
              InkWell(
                onTap: selectPhoto,

                borderRadius: BorderRadius.circular(12),

                child: Container(
                  width: double.infinity,
                  height: 180,

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(12),

                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),

                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,

                    children: [

                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 50,
                        color: Colors.grey.shade500,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Tap to add a photo",

                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )

            else

            // SELECTED PHOTO
              Stack(
                children: [

                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),

                    child: Image.file(
                      selectedImage!,

                      width: double.infinity,
                      height: 250,

                      fit: BoxFit.cover,
                    ),
                  ),

                  Positioned(
                    top: 10,
                    right: 10,

                    child: GestureDetector(
                      onTap: removePhoto,

                      child: Container(
                        padding: const EdgeInsets.all(8),

                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),

                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            // =========================
            // VERIFICATION QUESTION
            // =========================

            if (selectedType == "Found") ...[

              const SizedBox(height: 28),

              const Text(
                "Verification Question",

                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                "Create a question that only the rightful "
                    "owner would likely know.",

                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                verificationQuestionController,

                maxLines: 2,

                decoration: InputDecoration(
                  hintText:
                  "Example: What wallpaper is on the phone?",

                  prefixIcon: const Icon(
                    Icons.help_outline,
                  ),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // =========================
            // SUBMIT
            // =========================

            SizedBox(
              width: double.infinity,
              height: 54,

              child: ElevatedButton.icon(
                onPressed: isSubmitting ? null : submitReport,

                icon: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send,
                      ),

                label: Text(
                  isSubmitting ? "Submitting..." : "Submit Report",

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}