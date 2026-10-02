import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../models/item_model.dart';
import '../providers/claim_provider.dart';

class ClaimItemScreen extends StatefulWidget {
  final ItemModel item;

  const ClaimItemScreen({
    super.key,
    required this.item,
  });

  @override
  State<ClaimItemScreen> createState() => _ClaimItemScreenState();
}

class _ClaimItemScreenState extends State<ClaimItemScreen> {
  final TextEditingController answerController =
  TextEditingController();

  final TextEditingController detailsController =
  TextEditingController();

  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  @override
  void dispose() {
    answerController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  void submitClaim() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final claimProvider = context.read<ClaimProvider>();

    final success = await claimProvider.submitClaim(
      item: widget.item,
      answer: answerController.text.trim(),
      additionalDetails: detailsController.text.trim(),
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit claim: ${claimProvider.errorMessage}',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              SizedBox(width: 8),
              Text("Request Submitted"),
            ],
          ),

          content: const Text(
            "Your claim request has been submitted successfully. "
                "The owner or administrator will review your request.",
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Done"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Claim Item"),
        centerTitle: true,
      ),

      body: Form(
        key: _formKey,

        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              // =========================
              // ITEM INFORMATION
              // =========================

              const Text(
                "Item You're Claiming",

                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              Card(
                elevation: 2,

                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(16),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(14),

                  child: Row(
                    children: [

                      // IMAGE
                      ClipRRect(
                        borderRadius:
                        BorderRadius.circular(12),

                        child: _buildClaimItemImage(),
                      ),

                      const SizedBox(width: 14),

                      // INFORMATION
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [

                            Text(
                              widget.item.title,

                              maxLines: 2,
                              overflow:
                              TextOverflow.ellipsis,

                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              widget.item.category,

                              style: TextStyle(
                                color:
                                Colors.grey.shade700,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Row(
                              children: [

                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: Colors.grey,
                                ),

                                const SizedBox(width: 4),

                                Expanded(
                                  child: Text(
                                    widget.item.location,
                                    overflow:
                                    TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // =========================
              // VERIFICATION
              // =========================

              const Text(
                "Verify Ownership",

                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Answer the question below to help "
                    "verify that this item belongs to you.",

                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              // QUESTION
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius:
                  BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.blue.shade100,
                  ),
                ),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    const Row(
                      children: [

                        Icon(
                          Icons.help_outline,
                          color: Colors.blue,
                        ),

                        SizedBox(width: 8),

                        Text(
                          "Verification Question",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      (widget.item.verificationQuestion != null &&
                          widget.item.verificationQuestion!.trim().isNotEmpty)
                          ? widget.item.verificationQuestion!
                          : "What specific detail can you provide "
                          "about this item that is not shown in "
                          "the post?",

                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // ANSWER
              TextFormField(
                controller: answerController,

                maxLines: 4,

                decoration: InputDecoration(
                  hintText:
                  "Enter your answer...",

                  labelText:
                  "Your Answer",

                  alignLabelWithHint: true,

                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(12),
                  ),

                  focusedBorder:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(12),

                    borderSide:
                    const BorderSide(
                      color: Colors.blue,
                      width: 2,
                    ),
                  ),
                ),

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return "Please answer the verification question.";
                  }

                  if (value.trim().length < 3) {
                    return "Please provide more details.";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 25),

              // =========================
              // ADDITIONAL DETAILS
              // =========================

              const Text(
                "Additional Details",

                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Provide any additional information "
                    "that may help verify your ownership.",

                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: detailsController,

                maxLines: 4,

                decoration: InputDecoration(
                  hintText:
                  "Example: Where and when you lost the item...",

                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(12),
                  ),

                  focusedBorder:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(12),

                    borderSide:
                    const BorderSide(
                      color: Colors.blue,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // =========================
              // SUBMIT BUTTON
              // =========================

              Builder(builder: (context) {
                final isSubmitting = context.watch<ClaimProvider>().isSubmitting;

                return SizedBox(
                width: double.infinity,
                height: 54,

                child: ElevatedButton.icon(
                  onPressed:
                  isSubmitting
                      ? null
                      : submitClaim,

                  icon: isSubmitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,

                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons.assignment_turned_in,
                  ),

                  label: Text(
                    isSubmitting
                        ? "Submitting..."
                        : "Submit Claim Request",

                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
                );
              }),

              const SizedBox(height: 15),

              // INFORMATION
              Container(
                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius:
                  BorderRadius.circular(12),
                ),

                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade800,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        "Only submit a claim if you believe "
                            "this item belongs to you. False claims "
                            "may be reviewed by the administrator.",

                        style: TextStyle(
                          color:
                          Colors.orange.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClaimItemImage() {
    final localPath = widget.item.localImagePath;
    if (widget.item.imageUrl.isEmpty &&
        localPath != null &&
        localPath.isNotEmpty) {
      return Image.file(
        File(localPath),
        width: 85,
        height: 85,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
      );
    }

    if (widget.item.imageUrl.isEmpty) {
      return _imagePlaceholder();
    }

    return Image.network(
      widget.item.imageUrl,
      width: 85,
      height: 85,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 85,
      height: 85,
      color: Colors.grey.shade200,

      child: Icon(
        Icons.image_outlined,
        size: 40,
        color: Colors.grey.shade500,
      ),
    );
  }
}