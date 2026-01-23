import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  // Method specifically for sending Session Requests
  static Future<bool> sendSessionRequestEmail({
    required String toEmail,
    required String professorName,
    required String studentName, // We explicitly ask for this now
    required String studentEmail,
    required String messageContent,
  }) async {
    try {
      // Build the email body specifically here to ensure variables are inserted
      String subject = "Session Request from $studentName";

      return await _sendEmailViaDirectSMTP(
        toEmail: toEmail,
        subject: subject,
        fromName: "EduGuide App",
        // Pass the specific data to the internal method
        studentName: studentName,
        studentEmail: studentEmail,
        professorName: professorName,
        messageContent: messageContent,
      );
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }

  static Future<bool> _sendEmailViaDirectSMTP({
    required String toEmail,
    required String subject,
    required String fromName,
    // Add specific fields here for HTML construction
    required String studentName,
    required String studentEmail,
    required String professorName,
    required String messageContent,
  }) async {
    try {
      final smtpServer = SmtpServer(
        'smtp.gmail.com',
        port: 587,
        username: 'sahil253636@gmail.com',
        // MAKE SURE TO USE YOUR NEW, SECURE PASSWORD HERE
        password: dotenv.env['PASSWORD']!,
        ssl: false,
        allowInsecure: false,
      );

      // Construct the HTML with the variables inserted directly
      final htmlBody =
          '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e0e0e0;">
          <div style="background-color: #407BFF; padding: 20px; text-align: center;">
            <h1 style="color: white; margin: 0; font-size: 28px;">EduGuide</h1>
            <p style="color: white; margin: 5px 0 0 0; font-size: 18px;">Session Request</p>
          </div>
          <div style="padding: 30px; background-color: #f7f7fd;">
            <p style="color: #333; font-size: 18px;">Dear Professor $professorName,</p>
            <p style="color: #333; font-size: 18px;">A student has requested to meet with you:</p>
            
            <table style="width: 100%; margin-top: 20px; border-collapse: collapse;">
              <tr>
                <td style="padding: 10px 0; font-weight: bold; color: #555; width: 120px; font-size: 16px;">Student Name:</td>
                <td style="padding: 10px 0; color: #000; font-size: 16px;">$studentName</td> 
              </tr>
              <tr>
                <td style="padding: 10px 0; font-weight: bold; color: #555; font-size: 16px;">Student Email:</td>
                <td style="padding: 10px 0; color: #000; font-size: 16px;">$studentEmail</td>
              </tr>
              <tr>
                <td style="padding: 10px 0; font-weight: bold; color: #555; vertical-align: top; font-size: 16px;">Message:</td>
                <td style="padding: 10px 0; color: #000; font-size: 16px;">$messageContent</td>
              </tr>
            </table>
            
          </div>
          <div style="background-color: #407BFF; padding: 15px; text-align: center;">
            <p style="color: white; margin: 0; font-size: 14px;">
              This email was sent from the EduGuide mobile application
            </p>
          </div>
        </div>
      ''';

      final message = Message()
        ..from = Address('sahil253636@gmail.com', fromName)
        ..recipients.add(toEmail)
        ..subject = subject
        ..text =
            "Student $studentName wants to meet you. Email: $studentEmail. Message: $messageContent" // Fallback text
        ..html = htmlBody;

      final sendReport = await send(message, smtpServer);

      print('Email sent successfully to $toEmail');
      return true;
    } catch (e) {
      print('Error sending direct SMTP email: $e');
      return false;
    }
  }
}
