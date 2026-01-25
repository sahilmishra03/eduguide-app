const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// Configure nodemailer with Gmail using App Password
const transporter = nodemailer.createTransporter({
  service: 'gmail',
  auth: {
    user: 'sahilmishra03032005@gmail.com', // Your Gmail address
    pass: 'your-app-password-here', // Your Google App Password (not regular password)
  },
});

exports.sendEmail = functions.https.onCall(async (data, context) => {
  try {
    const { toEmail, subject, body, fromName } = data;

    // Validate input
    if (!toEmail || !subject || !body) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    const mailOptions = {
      from: `"${fromName || 'EduGuide App'}" <sahilmishra03032005@gmail.com>`,
      to: toEmail,
      subject: subject,
      text: body,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background-color: #407BFF; padding: 20px; text-align: center;">
            <h1 style="color: white; margin: 0;">EduGuide</h1>
            <p style="color: white; margin: 5px 0 0 0;">Session Request</p>
          </div>
          <div style="padding: 30px; background-color: #f7f7fd;">
            ${body.replace(/\n/g, '<br>')}
          </div>
          <div style="background-color: #407BFF; padding: 15px; text-align: center;">
            <p style="color: white; margin: 0; font-size: 12px;">
              This email was sent from the EduGuide mobile application
            </p>
          </div>
        </div>
      `
    };

    const result = await transporter.sendMail(mailOptions);
    console.log('Email sent successfully:', result.messageId);
    
    return { 
      success: true, 
      messageId: result.messageId,
      toEmail: toEmail,
      subject: subject
    };
  } catch (error) {
    console.error('Error sending email:', error);
    
    // Provide more specific error messages
    if (error.code === 'EAUTH') {
      throw new functions.https.HttpsError('permission-denied', 
        'Email authentication failed. Check your Gmail App Password.');
    } else if (error.code === 'ECONNECTION') {
      throw new functions.https.HttpsError('unavailable', 
        'Could not connect to email service. Please try again later.');
    } else {
      throw new functions.https.HttpsError('internal', 
        'Failed to send email: ' + error.message);
    }
  }
});

// Test function to verify email configuration
exports.testEmail = functions.https.onCall(async (data, context) => {
  try {
    const testMailOptions = {
      from: '"EduGuide Test" <sahilmishra03032005@gmail.com>',
      to: 'sahilmishra03032005@gmail.com',
      subject: 'Test Email from EduGuide',
      text: 'This is a test email to verify the email configuration is working.',
      html: '<p>This is a <strong>test email</strong> to verify the email configuration is working.</p>'
    };

    const result = await transporter.sendMail(testMailOptions);
    console.log('Test email sent successfully:', result.messageId);
    
    return { 
      success: true, 
      messageId: result.messageId,
      message: 'Test email sent successfully!'
    };
  } catch (error) {
    console.error('Error sending test email:', error);
    throw new functions.https.HttpsError('internal', 
      'Failed to send test email: ' + error.message);
  }
});
