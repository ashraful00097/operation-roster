import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class InterchangeRequestsScreen extends StatefulWidget {
  const InterchangeRequestsScreen({super.key});

  @override
  State<InterchangeRequestsScreen> createState() =>
      _InterchangeRequestsScreenState();
}

class _InterchangeRequestsScreenState
    extends State<InterchangeRequestsScreen> {
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color backgroundColor = Color(0xFFF4F6F9);

  bool isProcessing = false;

  User? get currentUser =>
      FirebaseAuth.instance.currentUser;

  // ===================================================
  // PROCESS ACCEPT / REJECT
  // MAIN ROSTER WILL NOT CHANGE
  // ===================================================

  Future<void> processRequest(
    DocumentSnapshot<Map<String, dynamic>> request,
    String newStatus,
  ) async {
    if (isProcessing) {
      return;
    }

    final user = currentUser;

    if (user == null) {
      showMessage(
        'User login করা নেই।',
      );
      return;
    }

    final data = request.data();

    if (data == null) {
      return;
    }

    final toUserId =
        data['toUserId']?.toString() ?? '';

    final status =
        data['status']?.toString() ?? '';

    // Only receiver can accept/reject.
    if (toUserId != user.uid) {
      showMessage(
        'এই request process করার permission নেই।',
      );
      return;
    }

    if (status != 'pending') {
      showMessage(
        'এই request already processed হয়েছে।',
      );
      return;
    }

    final isAccept =
        newStatus == 'accepted';

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(
            isAccept
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color:
                isAccept
                    ? Colors.green
                    : Colors.red,
            size: 38,
          ),

          title: Text(
            isAccept
                ? 'Accept Interchange?'
                : 'Reject Interchange?',
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          content: Text(
            isAccept
                ? 'Do you want to accept this interchange request?'
                : 'Do you want to reject this interchange request?',
            textAlign:
                TextAlign.center,
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
                  const Text(
                'Cancel',
              ),
            ),

            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    isAccept
                        ? primaryBlue
                        : Colors.red,
              ),

              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },

              child:
                  Text(
                isAccept
                    ? 'Accept'
                    : 'Reject',
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
      isProcessing = true;
    });

    try {
      // =================================================
      // IMPORTANT:
      // ONLY INTERCHANGE RECORD IS UPDATED.
      // MAIN ROSTER IS NEVER UPDATED.
      // =================================================

      await FirebaseFirestore.instance
          .collection(
            'interchange_requests',
          )
          .doc(request.id)
          .update({
        'status': newStatus,
        'processedAt':
            FieldValue.serverTimestamp(),
        'processedBy':
            user.uid,
      });

      if (!mounted) {
        return;
      }

      showMessage(
        isAccept
            ? 'Interchange accepted.'
            : 'Interchange rejected.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      showMessage(
        'Request update করা যায়নি: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  // ===================================================
  // SHARE ACCEPTED INTERCHANGE
  // ===================================================

  Future<void> shareInterchange(
    Map<String, dynamic> data,
  ) async {
    final fromName =
        data['fromName']?.toString() ?? '';

    final fromGroup =
        data['fromGroup']?.toString() ?? '';

    final toName =
        data['toName']?.toString() ?? '';

    final toGroup =
        data['toGroup']?.toString() ?? '';

    final duty =
        data['duty']?.toString() ?? '';

    final date =
        data['dateText']?.toString() ??
            data['date']?.toString() ??
            '';

    final status =
        data['status']?.toString() ?? '';

    final message = '''
DUTY INTERCHANGE

Person 1: $fromName
Group: $fromGroup

Person 2: $toName
Group: $toGroup

Duty: $duty Duty
Date: $date

Status: ${status.toUpperCase()}
''';

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: message,
          title:
              'Duty Interchange',
          subject:
              'Duty Interchange',
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      showMessage(
        'Share করা যায়নি: $error',
      );
    }
  }

  // ===================================================
  // FORMAT CREATED / PROCESSED DATE
  // ===================================================

  String formatTimestamp(
    dynamic value,
  ) {
    if (value is! Timestamp) {
      return 'Date unavailable';
    }

    final date =
        value.toDate();

    final day =
        date.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final month =
        date.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final year =
        date.year.toString();

    final hour =
        date.hour
            .toString()
            .padLeft(
              2,
              '0',
            );

    final minute =
        date.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$day/$month/$year $hour:$minute';
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
        content:
            Text(message),
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
    final user =
        currentUser;

    if (user == null) {
      return const Scaffold(
        body:
            Center(
          child:
              Text(
            'Please login first.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          backgroundColor,

      appBar:
          AppBar(
        backgroundColor:
            primaryBlue,

        foregroundColor:
            Colors.white,

        centerTitle:
            true,

        title:
            const Text(
          'Interchange Requests',
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body:
          StreamBuilder<
              QuerySnapshot<
                  Map<String, dynamic>>>(
        stream:
            FirebaseFirestore
                .instance
                .collection(
                  'interchange_requests',
                )
                .where(
                  Filter.or(
                    Filter(
                      'fromUserId',
                      isEqualTo:
                          user.uid,
                    ),
                    Filter(
                      'toUserId',
                      isEqualTo:
                          user.uid,
                    ),
                  ),
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

          if (snapshot.hasError) {
            return Center(
              child:
                  Padding(
                padding:
                    const EdgeInsets
                        .all(24),

                child:
                    Text(
                  'Error loading requests:\n'
                  '${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          final requests =
              List<
                  QueryDocumentSnapshot<
                      Map<String, dynamic>>>.from(
            snapshot.data?.docs ??
                [],
          );

          // =================================================
          // SORT NEWEST FIRST
          // =================================================

          requests.sort(
            (a, b) {
              final aTime =
                  a.data()['createdAt'];

              final bTime =
                  b.data()['createdAt'];

              if (aTime is Timestamp &&
                  bTime is Timestamp) {
                return bTime.compareTo(
                  aTime,
                );
              }

              return 0;
            },
          );

          // =================================================
          // INCOMING PENDING
          // =================================================

          final pending =
              requests.where(
            (request) {
              final data =
                  request.data();

              return data[
                          'toUserId'] ==
                      user.uid &&
                  data['status'] ==
                      'pending';
            },
          ).toList();

          // =================================================
          // HISTORY
          // =================================================

          final history =
              requests.where(
            (request) {
              final data =
                  request.data();

              final status =
                  data['status'];

              return status ==
                      'accepted' ||
                  status ==
                      'rejected' ||
                  status ==
                      'cancelled';
            },
          ).toList();

          return RefreshIndicator(
            onRefresh:
                () async {
              await Future<void>.delayed(
                const Duration(
                  milliseconds:
                      300,
                ),
              );
            },

            child:
                ListView(
              padding:
                  const EdgeInsets
                      .all(16),

              children: [
                // =================================================
                // PENDING TITLE
                // =================================================

                Row(
                  children: [
                    const Icon(
                      Icons
                          .notifications_active_rounded,
                      color:
                          primaryBlue,
                      size: 25,
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    const Expanded(
                      child:
                          Text(
                        'Pending Requests',
                        style:
                            TextStyle(
                          fontSize:
                              21,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ),

                    if (pending
                        .isNotEmpty)
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              9,
                          vertical:
                              5,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              Colors.red,

                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),

                        child:
                            Text(
                          pending
                              .length
                              .toString(),

                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize:
                                11,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                if (pending
                    .isEmpty)
                  emptyCard(
                    'No pending interchange requests.',
                  )
                else
                  ...pending.map(
                    pendingCard,
                  ),

                const SizedBox(
                  height: 30,
                ),

                // =================================================
                // HISTORY TITLE
                // =================================================

                const Row(
                  children: [
                    Icon(
                      Icons
                          .history_rounded,
                      color:
                          primaryBlue,
                      size: 25,
                    ),

                    SizedBox(
                      width: 8,
                    ),

                    Text(
                      'Interchange History',
                      style:
                          TextStyle(
                        fontSize:
                            21,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                if (history
                    .isEmpty)
                  emptyCard(
                    'No interchange history yet.',
                  )
                else
                  ...history.map(
                    historyCard,
                  ),

                const SizedBox(
                  height: 30,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===================================================
  // PENDING CARD
  // ===================================================

  Widget pendingCard(
    DocumentSnapshot<
        Map<String, dynamic>>
            request,
  ) {
    final data =
        request.data()!;

    final fromName =
        data['fromName']
                ?.toString() ??
            '';

    final fromGroup =
        data['fromGroup']
                ?.toString() ??
            '';


    final toGroup =
        data['toGroup']
                ?.toString() ??
            '';

    final duty =
        data['duty']
                ?.toString() ??
            '';

    final date =
        data['dateText']
                ?.toString() ??
            data['date']
                ?.toString() ??
            '';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
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
          18,
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha:
                  0.05,
            ),

            blurRadius:
                10,

            offset:
                const Offset(
              0,
              4,
            ),
          ),
        ],
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,

        children: [
          // =============================================
          // PERSON
          // =============================================

          Row(
            children: [
              CircleAvatar(
                radius:
                    27,

                backgroundColor:
                    const Color(
                  0xFFE3F2FD,
                ),

                child:
                    Text(
                  fromGroup.replaceFirst(
                    'G-',
                    '',
                  ),

                  style:
                      const TextStyle(
                    fontSize:
                        20,
                    fontWeight:
                        FontWeight
                            .bold,
                    color:
                        primaryBlue,
                  ),
                ),
              ),

              const SizedBox(
                width:
                    12,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Text(
                      fromName,

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
                      height:
                          3,
                    ),

                    Text(
                      '$fromGroup → $toGroup',

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

          const SizedBox(
            height:
                16,
          ),

          // =============================================
          // DUTY + DATE
          // =============================================

          Container(
            width:
                double.infinity,

            padding:
                const EdgeInsets
                    .all(
              13,
            ),

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF4F6F9,
              ),

              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child:
                Row(
              children: [
                Expanded(
                  child:
                      infoItem(
                    Icons
                        .access_time_rounded,
                    'Duty',
                    '$duty Duty',
                  ),
                ),

                Expanded(
                  child:
                      infoItem(
                    Icons
                        .calendar_month_rounded,
                    'Date',
                    date,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height:
                18,
          ),

          // =============================================
          // ACCEPT / REJECT
          // =============================================

          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton(
                  onPressed:
                      isProcessing
                          ? null
                          : () =>
                              processRequest(
                                request,
                                'rejected',
                              ),

                  style:
                      OutlinedButton
                          .styleFrom(
                    foregroundColor:
                        Colors.red,

                    side:
                        const BorderSide(
                      color:
                          Colors.red,
                    ),

                    minimumSize:
                        const Size(
                      double.infinity,
                      52,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),

                  child:
                      const Text(
                    'Reject',

                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width:
                    12,
              ),

              Expanded(
                child:
                    FilledButton(
                  onPressed:
                      isProcessing
                          ? null
                          : () =>
                              processRequest(
                                request,
                                'accepted',
                              ),

                  style:
                      FilledButton
                          .styleFrom(
                    backgroundColor:
                        primaryBlue,

                    minimumSize:
                        const Size(
                      double.infinity,
                      52,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),

                  child:
                      const Text(
                    'Accept',

                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================================================
  // HISTORY CARD
  // ===================================================

  Widget historyCard(
    DocumentSnapshot<
        Map<String, dynamic>>
            request,
  ) {
    final data =
        request.data()!;

    final fromName =
        data['fromName']
                ?.toString() ??
            '';

    final fromGroup =
        data['fromGroup']
                ?.toString() ??
            '';

    final toName =
        data['toName']
                ?.toString() ??
            '';

    final toGroup =
        data['toGroup']
                ?.toString() ??
            '';

    final duty =
        data['duty']
                ?.toString() ??
            '';

    final date =
        data['dateText']
                ?.toString() ??
            data['date']
                ?.toString() ??
            '';

    final status =
        data['status']
                ?.toString() ??
            '';

    final isAccepted =
        status ==
            'accepted';

    final isRejected =
        status ==
            'rejected';


    Color statusColor;

    String statusText;

    IconData statusIcon;

    if (isAccepted) {
      statusColor =
          Colors.green;

      statusText =
          'ACCEPTED';

      statusIcon =
          Icons.check_circle_rounded;
    } else if (isRejected) {
      statusColor =
          Colors.red;

      statusText =
          'REJECTED';

      statusIcon =
          Icons.cancel_rounded;
    } else {
      statusColor =
          Colors.orange;

      statusText =
          'CANCELLED';

      statusIcon =
          Icons
              .remove_circle_rounded;
    }

    return Container(
      margin:
          const EdgeInsets.only(
        bottom:
            12,
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
          18,
        ),

        border:
            Border.all(
          color:
              statusColor.withValues(
            alpha:
                0.25,
          ),
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,

        children: [
          // =============================================
          // TOP ROW
          // =============================================

          Row(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Text(
                      '$fromName ↔ $toName',

                      style:
                          const TextStyle(
                        fontSize:
                            17,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    const SizedBox(
                      height:
                          5,
                    ),

                    Text(
                      '$fromGroup → $toGroup',

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

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal:
                      9,
                  vertical:
                      6,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      statusColor
                          .withValues(
                    alpha:
                        0.10,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),

                child:
                    Row(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    Icon(
                      statusIcon,
                      size:
                          14,
                      color:
                          statusColor,
                    ),

                    const SizedBox(
                      width:
                          4,
                    ),

                    Text(
                      statusText,

                      style:
                          TextStyle(
                        fontSize:
                            9,
                        fontWeight:
                            FontWeight
                                .bold,
                        color:
                            statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                14,
          ),

          // =============================================
          // DUTY + DATE
          // =============================================

          Container(
            width:
                double.infinity,

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
                  BorderRadius.circular(
                12,
              ),
            ),

            child:
                Row(
              children: [
                Expanded(
                  child:
                      infoItem(
                    Icons
                        .access_time_rounded,
                    'Duty',
                    '$duty Duty',
                  ),
                ),

                Expanded(
                  child:
                      infoItem(
                    Icons
                        .calendar_month_rounded,
                    'Date',
                    date,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height:
                10,
          ),

          // =============================================
          // CREATED
          // =============================================

          Text(
            'Created: '
            '${formatTimestamp(
              data['createdAt'],
            )}',

            style:
                const TextStyle(
              fontSize:
                  11,
              color:
                  Colors.grey,
            ),
          ),

          if (data['processedAt'] !=
              null) ...[
            const SizedBox(
              height:
                  3,
            ),

            Text(
              'Processed: '
              '${formatTimestamp(
                data['processedAt'],
              )}',

              style:
                  const TextStyle(
                fontSize:
                    11,
                color:
                    Colors.grey,
              ),
            ),
          ],

          // =============================================
          // SHARE
          // ONLY ACCEPTED
          // =============================================

          if (isAccepted) ...[
            const SizedBox(
              height:
                  14,
            ),

            SizedBox(
              width:
                  double.infinity,

              height:
                  48,

              child:
                  OutlinedButton
                      .icon(
                onPressed:
                    () =>
                        shareInterchange(
                  data,
                ),

                icon:
                    const Icon(
                  Icons
                      .share_rounded,
                ),

                label:
                    const Text(
                  'Share Interchange',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),

                style:
                    OutlinedButton
                        .styleFrom(
                  foregroundColor:
                      primaryBlue,

                  side:
                      const BorderSide(
                    color:
                        primaryBlue,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===================================================
  // INFO ITEM
  // ===================================================

  Widget infoItem(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size:
              20,
          color:
              primaryBlue,
        ),

        const SizedBox(
          width:
              7,
        ),

        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [
              Text(
                title,

                style:
                    const TextStyle(
                  fontSize:
                      10,
                  color:
                      Colors.grey,
                ),
              ),

              const SizedBox(
                height:
                    2,
              ),

              Text(
                value,

                overflow:
                    TextOverflow.ellipsis,

                style:
                    const TextStyle(
                  fontSize:
                      13,
                  fontWeight:
                      FontWeight
                          .bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===================================================
  // EMPTY CARD
  // ===================================================

  Widget emptyCard(
    String message,
  ) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets
              .all(
        24,
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
        children: [
          const Icon(
            Icons
                .notifications_none_rounded,
            size:
                42,
            color:
                Colors.grey,
          ),

          const SizedBox(
            height:
                8,
          ),

          Text(
            message,

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              color:
                  Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}