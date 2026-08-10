import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState
    extends State<ProfileSetupScreen> {
  final nameController = TextEditingController();

  static const Color primaryBlue =
      Color(0xFF1565C0);

  static const Color backgroundColor =
      Color(0xFFF4F6F9);

  // ===================================================
  // DUTY TYPE
  // ===================================================

  String dutyType = 'shift';

  String selectedGroup = 'G-A';

  bool isSaving = false;

  final groups = const [
    'G-A',
    'G-B',
    'G-C',
    'G-D',
  ];

  // ===================================================
  // SAVE PROFILE
  // ===================================================

  Future<void> saveProfile() async {
    final name =
        nameController.text.trim();

    if (name.isEmpty) {
      showMessage(
        'Please enter your name.',
      );
      return;
    }

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage(
        'User login করা নেই।',
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final Map<String, dynamic> profileData = {
        'name': name,
        'email': user.email ?? '',
        'dutyType': dutyType,
        'createdAt':
            FieldValue.serverTimestamp(),
      };

      // ===============================================
      // SHIFT
      // ===============================================

      if (dutyType == 'shift') {
        profileData['group'] =
            selectedGroup;
      }

      // ===============================================
      // SAVE PROFILE
      // ===============================================

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
            profileData,
            SetOptions(
              merge: true,
            ),
          );

      // ===============================================
      // REGULAR USER
      // Remove old group if previously selected
      // ===============================================

      if (dutyType == 'regular') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'group': FieldValue.delete(),
        });
      }

      if (!mounted) {
        return;
      }

      showMessage(
        'Profile saved successfully.',
      );
    } catch (error) {
      showMessage(
        'Profile save করা যায়নি: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ===================================================
  // MESSAGE
  // ===================================================

  void showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ===================================================
  // DISPOSE
  // ===================================================

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  // ===================================================
  // BUILD
  // ===================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          backgroundColor,

      // =================================================
      // APP BAR
      // =================================================

      appBar: AppBar(
        backgroundColor:
            primaryBlue,

        foregroundColor:
            Colors.white,

        centerTitle: true,

        title: const Text(
          'Setup Profile',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      // =================================================
      // BODY
      // =================================================

      body: Center(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),

          child:
              ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 450,
            ),

            child:
                Card(
              elevation: 3,

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),

              child:
                  Padding(
                padding:
                    const EdgeInsets.all(
                  24,
                ),

                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,

                  children: [
                    // =================================
                    // ICON
                    // =================================

                    const Icon(
                      Icons
                          .person_rounded,

                      size: 64,

                      color:
                          primaryBlue,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // =================================
                    // TITLE
                    // =================================

                    const Text(
                      'Create Your Profile',

                      textAlign:
                          TextAlign.center,

                      style:
                          TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    const Text(
                      'Enter your name and duty type',

                      textAlign:
                          TextAlign.center,

                      style:
                          TextStyle(
                        color:
                            Colors.grey,
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    // =================================
                    // NAME
                    // =================================

                    TextField(
                      controller:
                          nameController,

                      textCapitalization:
                          TextCapitalization
                              .words,

                      enabled:
                          !isSaving,

                      decoration:
                          InputDecoration(
                        labelText:
                            'Full Name',

                        prefixIcon:
                            const Icon(
                          Icons
                              .person_outline,
                        ),

                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    // =================================
                    // DUTY TYPE
                    // =================================

                    const Text(
                      'Duty Type',

                      style:
                          TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Row(
                      children: [
                        // =============================
                        // SHIFT
                        // =============================

                        Expanded(
                          child:
                              dutyTypeCard(
                            type:
                                'shift',

                            title:
                                'Shift',

                            subtitle:
                                'Has duty group',

                            icon:
                                Icons
                                    .sync_alt_rounded,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        // =============================
                        // REGULAR
                        // =============================

                        Expanded(
                          child:
                              dutyTypeCard(
                            type:
                                'regular',

                            title:
                                'Regular',

                            subtitle:
                                'No duty group',

                            icon:
                                Icons
                                    .person_outline_rounded,
                          ),
                        ),
                      ],
                    ),

                    // =================================
                    // GROUP
                    // =================================

                    if (dutyType ==
                        'shift') ...[
                      const SizedBox(
                        height: 22,
                      ),

                      DropdownButtonFormField<
                          String>(
                        initialValue:
                            selectedGroup,

                        decoration:
                            InputDecoration(
                          labelText:
                              'Duty Group',

                          prefixIcon:
                              const Icon(
                            Icons
                                .groups_outlined,
                          ),

                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                        ),

                        items:
                            groups.map(
                          (group) {
                            return DropdownMenuItem<
                                String>(
                              value:
                                  group,

                              child:
                                  Text(
                                group,
                              ),
                            );
                          },
                        ).toList(),

                        onChanged:
                            isSaving
                                ? null
                                : (
                                    value,
                                  ) {
                                    if (value ==
                                        null) {
                                      return;
                                    }

                                    setState(() {
                                      selectedGroup =
                                          value;
                                    });
                                  },
                      ),
                    ],

                    const SizedBox(
                      height: 28,
                    ),

                    // =================================
                    // SAVE
                    // =================================

                    SizedBox(
                      height: 52,

                      child:
                          FilledButton(
                        onPressed:
                            isSaving
                                ? null
                                : saveProfile,

                        style:
                            FilledButton
                                .styleFrom(
                          backgroundColor:
                              primaryBlue,

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                        ),

                        child:
                            isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Save Profile',

                                    style:
                                        TextStyle(
                                      fontSize:
                                          16,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===================================================
  // DUTY TYPE CARD
  // ===================================================

  Widget dutyTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected =
        dutyType == type;

    return InkWell(
      borderRadius:
          BorderRadius.circular(
        14,
      ),

      onTap: isSaving
          ? null
          : () {
              setState(() {
                dutyType = type;
              });
            },

      child:
          AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 200,
        ),

        padding:
            const EdgeInsets.all(
          14,
        ),

        decoration:
            BoxDecoration(
          color: isSelected
              ? const Color(
                  0xFFE3F2FD,
                )
              : Colors.white,

          borderRadius:
              BorderRadius.circular(
            14,
          ),

          border:
              Border.all(
            color: isSelected
                ? primaryBlue
                : Colors.grey.shade300,

            width:
                isSelected
                    ? 1.8
                    : 1,
          ),
        ),

        child:
            Column(
          children: [
            Icon(
              icon,

              size: 30,

              color: isSelected
                  ? primaryBlue
                  : Colors.grey,
            ),

            const SizedBox(
              height: 7,
            ),

            Text(
              title,

              style:
                  TextStyle(
                fontSize: 15,

                fontWeight:
                    FontWeight.bold,

                color: isSelected
                    ? primaryBlue
                    : Colors.black87,
              ),
            ),

            const SizedBox(
              height: 3,
            ),

            Text(
              subtitle,

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                fontSize: 10,
                color:
                    Colors.grey,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Icon(
              isSelected
                  ? Icons
                      .radio_button_checked
                  : Icons
                      .radio_button_unchecked,

              size: 20,

              color: isSelected
                  ? primaryBlue
                  : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}