import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InterchangeScreen extends StatefulWidget {
  const InterchangeScreen({super.key});

  @override
  State<InterchangeScreen> createState() =>
      _InterchangeScreenState();
}

class _InterchangeScreenState extends State<InterchangeScreen> {
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color backgroundColor = Color(0xFFF4F6F9);

  String? selectedGroup;
  bool isLoading = false;

  final groups = const [
    'G-A',
    'G-B',
    'G-C',
    'G-D',
  ];

  User? get currentUser =>
      FirebaseAuth.instance.currentUser;

  // ===================================================
  // DATE FORMAT
  // ===================================================

  String formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ===================================================
  // GET PENDING OUTGOING REQUESTS
  // ===================================================

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      getMyPendingRequests() async {
    final user = currentUser;

    if (user == null) {
      return [];
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('interchange_requests')
        .where(
          'fromUserId',
          isEqualTo: user.uid,
        )
        .get();

    return snapshot.docs.where((doc) {
      final data = doc.data();

      return data['status'] == 'pending';
    }).toList();
  }

  // ===================================================
  // CHECK IF PERSON ALREADY HAS PENDING REQUEST
  // ===================================================

  Future<bool> hasPendingRequestForPerson(
    String personId,
  ) async {
    final requests =
        await getMyPendingRequests();

    return requests.any(
      (request) {
        final data = request.data();

        return data['toUserId'] == personId;
      },
    );
  }

  // ===================================================
  // SELECT DUTY + DATE
  // ===================================================

  Future<Map<String, dynamic>?> selectDutyAndDate({
    String initialDuty = 'Day',
    DateTime? initialDate,
  }) async {
    String selectedDuty = initialDuty;
    DateTime selectedDate =
        initialDate ?? DateTime.now();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Select Duty & Date',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Duty',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'Day',
                        label: Text('Day'),
                        icon: Icon(
                          Icons.wb_sunny_rounded,
                        ),
                      ),
                      ButtonSegment<String>(
                        value: 'Night',
                        label: Text('Night'),
                        icon: Icon(
                          Icons.nightlight_round,
                        ),
                      ),
                    ],
                    selected: {
                      selectedDuty,
                    },
                    onSelectionChanged:
                        (selection) {
                      setDialogState(() {
                        selectedDuty =
                            selection.first;
                      });
                    },
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  InkWell(
                    borderRadius:
                        BorderRadius.circular(12),
                    onTap: () async {
                      final picked =
                          await showDatePicker(
                        context: context,
                        initialDate:
                            selectedDate,
                        firstDate:
                            DateTime(2025),
                        lastDate:
                            DateTime(2035),
                      );

                      if (picked != null) {
                        setDialogState(() {
                          selectedDate =
                              picked;
                        });
                      }
                    },

                    child: Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(15),

                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade400,
                        ),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),

                      child: Row(
                        children: [
                          const Icon(
                            Icons
                                .calendar_month_rounded,
                            color:
                                primaryBlue,
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          Text(
                            formatDate(
                              selectedDate,
                            ),
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child: const Text(
                    'Cancel',
                  ),
                ),

                FilledButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop({
                      'duty': selectedDuty,
                      'date':
                          dateKey(selectedDate),
                      'dateText':
                          formatDate(
                        selectedDate,
                      ),
                    });
                  },
                  child: const Text(
                    'Continue',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===================================================
  // SEND REQUEST
  // ===================================================

  Future<void> sendRequest(
    DocumentSnapshot<Map<String, dynamic>>
        person,
  ) async {
    final user = currentUser;

    if (user == null) {
      showMessage(
        'User login করা নেই।',
      );
      return;
    }

    if (isLoading) {
      return;
    }

    final data = person.data();

    if (data == null) {
      return;
    }

    // -----------------------------------------------
    // CHECK DUPLICATE
    // -----------------------------------------------

    final alreadyPending =
        await hasPendingRequestForPerson(
      person.id,
    );

    if (!mounted) {
      return;
    }

    if (alreadyPending) {
      showMessage(
        'এই person-এর জন্য একটি pending request already আছে।',
      );
      return;
    }

    // -----------------------------------------------
    // MY PROFILE
    // -----------------------------------------------

    final myProfile =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    if (!mounted) {
      return;
    }

    final myData =
        myProfile.data();

    if (myData == null) {
      showMessage(
        'Your profile পাওয়া যায়নি।',
      );
      return;
    }

    final fromName =
        myData['name']?.toString() ?? '';

    final fromGroup =
        myData['group']?.toString() ?? '';

    final toName =
        data['name']?.toString() ?? '';

    final toGroup =
        data['group']?.toString() ?? '';

    // -----------------------------------------------
    // DUTY + DATE
    // -----------------------------------------------

    final selection =
        await selectDutyAndDate();

    if (!mounted || selection == null) {
      return;
    }

    final duty =
        selection['duty']?.toString() ?? '';

    final requestDate =
        selection['date']?.toString() ?? '';

    final requestDateText =
        selection['dateText']?.toString() ?? '';

    // -----------------------------------------------
    // CONFIRM
    // -----------------------------------------------

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Send Interchange Request?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: Text(
            '$toName ($toGroup)\n\n'
            'Duty: $duty Duty\n'
            'Date: $requestDateText',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),

            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Send',
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // ---------------------------------------------
      // DOUBLE CHECK BEFORE CREATE
      // ---------------------------------------------

      final pendingRequests =
          await getMyPendingRequests();

      final duplicate =
          pendingRequests.any(
        (request) {
          final requestData =
              request.data();

          return requestData['toUserId'] ==
              person.id;
        },
      );

      if (duplicate) {
        throw Exception(
          'এই person-এর জন্য pending request already আছে।',
        );
      }

      // ---------------------------------------------
      // CREATE RECORD
      // ---------------------------------------------

      await FirebaseFirestore.instance
          .collection(
            'interchange_requests',
          )
          .add({
        'fromUserId': user.uid,
        'fromName': fromName,
        'fromGroup': fromGroup,

        'toUserId': person.id,
        'toName': toName,
        'toGroup': toGroup,

        'duty': duty,
        'date': requestDate,
        'dateText': requestDateText,

        'status': 'pending',

        'createdAt':
            FieldValue.serverTimestamp(),

        'processedAt': null,
        'processedBy': null,
      });

      if (!mounted) {
        return;
      }

      showMessage(
        'Interchange request sent.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      showMessage(
        'Request পাঠানো যায়নি: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ===================================================
  // EDIT REQUEST
  // ===================================================

  Future<void> editRequest(
    DocumentSnapshot<Map<String, dynamic>>
        request,
  ) async {
    final data = request.data();

    if (data == null) {
      return;
    }

    if (data['status'] != 'pending') {
      showMessage(
        'শুধু pending request edit করা যাবে।',
      );
      return;
    }

    final oldDuty =
        data['duty']?.toString() ?? 'Day';

    final oldDate =
        data['date']?.toString();

    DateTime initialDate =
        DateTime.now();

    if (oldDate != null) {
      final parts =
          oldDate.split('-');

      if (parts.length == 3) {
        final year =
            int.tryParse(parts[0]);

        final month =
            int.tryParse(parts[1]);

        final day =
            int.tryParse(parts[2]);

        if (year != null &&
            month != null &&
            day != null) {
          initialDate = DateTime(
            year,
            month,
            day,
          );
        }
      }
    }

    final selection =
        await selectDutyAndDate(
      initialDuty: oldDuty,
      initialDate: initialDate,
    );

    if (!mounted || selection == null) {
      return;
    }

    final newDuty =
        selection['duty']?.toString() ?? '';

    final newDate =
        selection['date']?.toString() ?? '';

    final newDateText =
        selection['dateText']?.toString() ?? '';

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Save Changes?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: Text(
            'Duty: $newDuty Duty\n'
            'Date: $newDateText',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),

            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Save',
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection(
            'interchange_requests',
          )
          .doc(request.id)
          .update({
        'duty': newDuty,
        'date': newDate,
        'dateText': newDateText,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      showMessage(
        'Interchange request updated.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      showMessage(
        'Update করা যায়নি: $error',
      );
    }
  }

  // ===================================================
  // CANCEL REQUEST
  // ===================================================

  Future<void> cancelRequest(
    DocumentSnapshot<Map<String, dynamic>>
        request,
  ) async {
    final data = request.data();

    if (data == null) {
      return;
    }

    if (data['status'] != 'pending') {
      showMessage(
        'শুধু pending request cancel করা যাবে।',
      );
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Cancel Request?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: const Text(
            'এই interchange request cancel করতে চান?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Keep',
              ),
            ),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    Colors.red,
              ),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Cancel Request',
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection(
            'interchange_requests',
          )
          .doc(request.id)
          .update({
        'status': 'cancelled',
        'cancelledAt':
            FieldValue.serverTimestamp(),
        'cancelledBy':
            currentUser?.uid,
      });

      if (!mounted) {
        return;
      }

      showMessage(
        'Interchange request cancelled.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      showMessage(
        'Cancel করা যায়নি: $error',
      );
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
  // BUILD
  // ===================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final user = currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please login first.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          backgroundColor,

      appBar: AppBar(
        backgroundColor:
            primaryBlue,
        foregroundColor:
            Colors.white,
        centerTitle: true,

        title: const Text(
          'Person Interchange',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<
          DocumentSnapshot<
              Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),

        builder: (
          context,
          myProfileSnapshot,
        ) {
          if (myProfileSnapshot
                  .connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final myProfile =
              myProfileSnapshot.data?.data();

          if (myProfile == null) {
            return const Center(
              child: Text(
                'Profile পাওয়া যায়নি।',
              ),
            );
          }

          final myGroup =
              myProfile['group']
                      ?.toString() ??
                  '';

          return StreamBuilder<
              QuerySnapshot<
                  Map<String, dynamic>>>(
            stream:
                FirebaseFirestore.instance
                    .collection(
                      'interchange_requests',
                    )
                    .where(
                      'fromUserId',
                      isEqualTo:
                          user.uid,
                    )
                    .snapshots(),

            builder: (
              context,
              requestSnapshot,
            ) {
              final pendingRequests =
                  requestSnapshot.data?.docs
                          .where(
                        (doc) {
                          return doc.data()[
                                  'status'] ==
                              'pending';
                        },
                      )
                          .toList() ??
                      [];

              final pendingPersonIds =
                  pendingRequests
                      .map(
                        (doc) =>
                            doc.data()[
                                'toUserId'],
                      )
                      .whereType<String>()
                      .toSet();

              return Column(
                children: [
                  // ===================================
                  // MY PROFILE
                  // ===================================

                  Container(
                    width:
                        double.infinity,
                    margin:
                        const EdgeInsets.all(
                      16,
                    ),
                    padding:
                        const EdgeInsets.all(
                      18,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(
                            alpha: 0.05,
                          ),
                          blurRadius: 12,
                          offset:
                              const Offset(
                            0,
                            4,
                          ),
                        ),
                      ],
                    ),

                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 27,
                          backgroundColor:
                              const Color(
                            0xFFE3F2FD,
                          ),
                          child: Text(
                            myGroup.replaceFirst(
                              'G-',
                              '',
                            ),
                            style:
                                const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  primaryBlue,
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 14,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                myProfile[
                                            'name']
                                        ?.toString() ??
                                    '',
                                style:
                                    const TextStyle(
                                  fontSize:
                                      18,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                'Your Group: $myGroup',
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.grey,
                                  fontSize:
                                      13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ===================================
                  // GROUP SELECT
                  // ===================================

                  Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),

                    child:
                        DropdownButtonFormField<
                            String>(
                      initialValue:
                          selectedGroup,

                      decoration:
                          InputDecoration(
                        labelText:
                            'Select another group',
                        prefixIcon:
                            const Icon(
                          Icons.groups_rounded,
                          color:
                              primaryBlue,
                        ),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                        filled: true,
                        fillColor:
                            Colors.white,
                      ),

                      items: groups
                          .where(
                            (group) =>
                                group !=
                                myGroup,
                          )
                          .map(
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
                          )
                          .toList(),

                      onChanged:
                          (value) {
                        setState(() {
                          selectedGroup =
                              value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // ===================================
                  // PEOPLE
                  // ===================================

                  Expanded(
                    child:
                        selectedGroup == null
                            ? const Center(
                                child: Text(
                                  'Select a group to see people.',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                              )
                            : StreamBuilder<
                                QuerySnapshot<
                                    Map<String,
                                        dynamic>>>(
                                stream:
                                    FirebaseFirestore
                                        .instance
                                        .collection(
                                          'users',
                                        )
                                        .where(
                                          'group',
                                          isEqualTo:
                                              selectedGroup,
                                        )
                                        .snapshots(),

                                builder: (
                                  context,
                                  snapshot,
                                ) {
                                  if (snapshot
                                          .connectionState ==
                                      ConnectionState
                                          .waiting) {
                                    return const Center(
                                      child:
                                          CircularProgressIndicator(),
                                    );
                                  }

                                  if (snapshot
                                      .hasError) {
                                    return Center(
                                      child:
                                          Text(
                                        'Error: ${snapshot.error}',
                                      ),
                                    );
                                  }

                                  final people =
                                      snapshot.data
                                              ?.docs ??
                                          [];

                                  if (people
                                      .isEmpty) {
                                    return const Center(
                                      child:
                                          Text(
                                        'No person found in this group.',
                                        style:
                                            TextStyle(
                                          color:
                                              Colors.grey,
                                        ),
                                      ),
                                    );
                                  }

                                  return ListView
                                      .separated(
                                    padding:
                                        const EdgeInsets
                                            .fromLTRB(
                                      16,
                                      0,
                                      16,
                                      20,
                                    ),

                                    itemCount:
                                        people.length,

                                    separatorBuilder:
                                        (
                                      context,
                                      index,
                                    ) {
                                      return const SizedBox(
                                        height:
                                            10,
                                      );
                                    },

                                    itemBuilder:
                                        (
                                      context,
                                      index,
                                    ) {
                                      final person =
                                          people[index];

                                      final data =
                                          person.data();

                                      final name =
                                          data['name']
                                                  ?.toString() ??
                                              '';

                                      final group =
                                          data['group']
                                                  ?.toString() ??
                                              '';

                                      final hasPending =
                                          pendingPersonIds
                                              .contains(
                                        person.id,
                                      );

                                      return Container(
                                        decoration:
                                            BoxDecoration(
                                          color:
                                              Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(
                                            16,
                                          ),
                                        ),

                                        child:
                                            ListTile(
                                          contentPadding:
                                              const EdgeInsets
                                                  .symmetric(
                                            horizontal:
                                                16,
                                            vertical:
                                                6,
                                          ),

                                          leading:
                                              CircleAvatar(
                                            backgroundColor:
                                                const Color(
                                              0xFFE3F2FD,
                                            ),
                                            child:
                                                Text(
                                              group.replaceFirst(
                                                'G-',
                                                '',
                                              ),
                                              style:
                                                  const TextStyle(
                                                fontWeight:
                                                    FontWeight.bold,
                                                color:
                                                    primaryBlue,
                                              ),
                                            ),
                                          ),

                                          title:
                                              Text(
                                            name,
                                            style:
                                                const TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),

                                          subtitle:
                                              Text(
                                            group,
                                          ),

                                          trailing:
                                              hasPending
                                                  ? OutlinedButton.icon(
                                                      onPressed:
                                                          null,
                                                      icon:
                                                          const Icon(
                                                        Icons
                                                            .check_circle_outline_rounded,
                                                        size:
                                                            17,
                                                      ),
                                                      label:
                                                          const Text(
                                                        'Sent',
                                                      ),
                                                    )
                                                  : FilledButton(
                                                      onPressed:
                                                          isLoading
                                                              ? null
                                                              : () =>
                                                                  sendRequest(
                                                                    person,
                                                                  ),
                                                      style:
                                                          FilledButton.styleFrom(
                                                        backgroundColor:
                                                            primaryBlue,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                            10,
                                                          ),
                                                        ),
                                                      ),
                                                      child:
                                                          const Text(
                                                        'Request',
                                                      ),
                                                    ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                  ),

                  // ===================================
                  // MY PENDING REQUESTS
                  // ===================================

                  if (pendingRequests
                      .isNotEmpty)
                    Container(
                      width:
                          double.infinity,
                      margin:
                          const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        16,
                      ),
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),

                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'My Pending Requests',
                            style:
                                TextStyle(
                              fontSize:
                                  18,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          ...pendingRequests
                              .map(
                            (request) {
                              final data =
                                  request.data();

                              final toName =
                                  data['toName']
                                          ?.toString() ??
                                      '';

                              final duty =
                                  data['duty']
                                          ?.toString() ??
                                      '';

                              final date =
                                  data['dateText']
                                          ?.toString() ??
                                      '';

                              return Container(
                                margin:
                                    const EdgeInsets
                                        .only(
                                  bottom:
                                      8,
                                ),

                                padding:
                                    const EdgeInsets
                                        .all(
                                  12,
                                ),

                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(
                                    0xFFF4F6F9,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    12,
                                  ),
                                ),

                                child:
                                    Row(
                                  children: [
                                    Expanded(
                                      child:
                                          Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            toName,
                                            style:
                                                const TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                          const SizedBox(
                                            height:
                                                3,
                                          ),
                                          Text(
                                            '$duty Duty • $date',
                                            style:
                                                const TextStyle(
                                              fontSize:
                                                  12,
                                              color:
                                                  Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    IconButton(
                                      tooltip:
                                          'Edit',
                                      onPressed:
                                          () =>
                                              editRequest(
                                        request,
                                      ),
                                      icon:
                                          const Icon(
                                        Icons
                                            .edit_rounded,
                                        color:
                                            primaryBlue,
                                      ),
                                    ),

                                    IconButton(
                                      tooltip:
                                          'Cancel',
                                      onPressed:
                                          () =>
                                              cancelRequest(
                                        request,
                                      ),
                                      icon:
                                          const Icon(
                                        Icons
                                            .delete_outline_rounded,
                                        color:
                                            Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}