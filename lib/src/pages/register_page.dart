import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'auth_service.dart';
// import 'home_page.dart'; // Assuming you have a HomePage to navigate to after successful registration
import 'main_page.dart'; // Assuming you have a HomePage to navigate to after successful registration



class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController confirmPassController = TextEditingController();
  
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _termsAccepted = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF21899C),
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: size.height,
            child: Stack(
              children: <Widget>[
                //left side background design. I use a svg image here
                Positioned(
                  left: -34,
                  top: 181.0,
                  child: SvgPicture.string(
                    // Group 3178
                    '<svg viewBox="-34.0 181.0 99.0 99.0" ><path transform="translate(-34.0, 181.0)" d="M 74.25 0 L 99 49.5 L 74.25 99 L 24.74999618530273 99 L 0 49.49999618530273 L 24.7500057220459 0 Z" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(-26.57, 206.25)" d="M 0 0 L 42.07500076293945 16.82999992370605 L 84.15000152587891 0" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(15.5, 223.07)" d="M 0 56.42999649047852 L 0 0" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                    width: 99.0,
                    height: 99.0,
                  ),
                ),

                //right side background design. I use a svg image here
                Positioned(
                  right: -52,
                  top: 45.0,
                  child: SvgPicture.string(
                    // Group 3177
                    '<svg viewBox="288.0 45.0 139.0 139.0" ><path transform="translate(288.0, 45.0)" d="M 104.25 0 L 139 69.5 L 104.25 139 L 34.74999618530273 139 L 0 69.5 L 34.75000762939453 0 Z" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(298.42, 80.45)" d="M 0 0 L 59.07500076293945 23.63000106811523 L 118.1500015258789 0" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(357.5, 104.07)" d="M 0 79.22999572753906 L 0 0" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                    width: 139.0,
                    height: 139.0,
                  ),
                ),

                //content ui
                Positioned(
                  top: 8.0,
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            //logo section
                            Column(
                              children: [
                                logo(size.height / 8, size.height / 8),
                                const SizedBox(
                                  height: 16,
                                ),
                                richText(23.12),
                              ],
                            ),
                            const SizedBox(
                              height: 16,
                            ),

                            //continue with email for sign in app text
                            Text(
                              'Continue with email for sign in App',
                              style: GoogleFonts.inter(
                                fontSize: 14.0,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(
                              height: 16,
                            ),

                            // Display error message if any
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.inter(
                                    fontSize: 14.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                            //input fields
                            Column(
                              children: [
                                nameTextField(size),
                                const SizedBox(
                                  height: 8,
                                ),
                                emailTextField(size),
                                const SizedBox(
                                  height: 8,
                                ),
                                passwordTextField(size),
                                const SizedBox(
                                  height: 8,
                                ),
                                confirmPasswordTextField(size),
                                const SizedBox(
                                  height: 16,
                                ),
                                buildTermsAndConditions(size),
                              ],
                            ),
                            const SizedBox(
                              height: 16,
                            ),

                            //register button & continue with text
                            Column(
                              children: [
                                _isLoading 
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : registerButton(size),
                                const SizedBox(
                                  height: 16,
                                ),
                                buildContinueText(),
                              ],
                            ),
                            const SizedBox(
                              height: 16,
                            ),

                            //footer section with social buttons and login text
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Di metode build, tambahkan tombol sign-in Google:
                                signInGoogleFacebookButton(
                                    MediaQuery.of(context).size, 
                                    () => _handleGoogleSignIn(),  // Gunakan arrow function
                                  ),
                                const SizedBox(
                                  height: 16,
                                ),
                                buildFooter(size, context),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget logo(double height_, double width_) {
    return Image.asset(
      'assets/coco.png',  // Changed from SVG to PNG
      height: height_,
      width: width_,
      fit: BoxFit.contain,
    );
  }

  Widget richText(double fontSize) {
    return Text.rich(
      TextSpan(
        style: GoogleFonts.inter(
          fontSize: 23.12,
          color: Colors.white,
          letterSpacing: 1.999999953855673,
        ),
        children: const [
          TextSpan(
            text: 'REGISTER',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: 'PAGE',
            style: TextStyle(
              color: Color(0xFFFE9879),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget nameTextField(Size size) {
    return Container(
      alignment: Alignment.center,
      height: size.height / 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: const Color(0xFF4DA1B0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            //person icon
            const Icon(
              Icons.person_outline,
              color: Colors.white70,
            ),
            const SizedBox(
              width: 16,
            ),

            //divider svg
            SvgPicture.string(
              '<svg viewBox="99.0 332.0 1.0 15.5" ><path transform="translate(99.0, 332.0)" d="M 0 0 L 0 15.5" fill="none" fill-opacity="0.6" stroke="#ffffff" stroke-width="1" stroke-opacity="0.6" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
              width: 1.0,
              height: 15.5,
            ),
            const SizedBox(
              width: 16,
            ),

            //full name textField
            Expanded(
              child: TextFormField(
                controller: nameController,
                maxLines: 1,
                cursorColor: Colors.white70,
                keyboardType: TextInputType.name,
                style: GoogleFonts.inter(
                  fontSize: 14.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14.0,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    errorStyle: GoogleFonts.inter(
                      fontSize: 12.0,
                      color: Colors.red[300],
                    ),
                    border: InputBorder.none),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget emailTextField(Size size) {
    return Container(
      alignment: Alignment.center,
      height: size.height / 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: const Color(0xFF4DA1B0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            //mail icon
            const Icon(
              Icons.mail_rounded,
              color: Colors.white70,
            ),
            const SizedBox(
              width: 16,
            ),

            //divider svg
            SvgPicture.string(
              '<svg viewBox="99.0 332.0 1.0 15.5" ><path transform="translate(99.0, 332.0)" d="M 0 0 L 0 15.5" fill="none" fill-opacity="0.6" stroke="#ffffff" stroke-width="1" stroke-opacity="0.6" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
              width: 1.0,
              height: 15.5,
            ),
            const SizedBox(
              width: 16,
            ),

            //email address textField
            Expanded(
              child: TextFormField(
                controller: emailController,
                maxLines: 1,
                cursorColor: Colors.white70,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.inter(
                  fontSize: 14.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                decoration: InputDecoration(
                    hintText: 'Enter your email address',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14.0,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    errorStyle: GoogleFonts.inter(
                      fontSize: 12.0,
                      color: Colors.red[300],
                    ),
                    border: InputBorder.none),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget passwordTextField(Size size) {
    return Container(
      alignment: Alignment.center,
      height: size.height / 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: const Color(0xFF4DA1B0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            //lock logo here
            const Icon(
              Icons.lock,
              color: Colors.white70,
            ),
            const SizedBox(
              width: 16,
            ),

            //divider svg
            SvgPicture.string(
              '<svg viewBox="99.0 332.0 1.0 15.5" ><path transform="translate(99.0, 332.0)" d="M 0 0 L 0 15.5" fill="none" fill-opacity="0.6" stroke="#ffffff" stroke-width="1" stroke-opacity="0.6" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
              width: 1.0,
              height: 15.5,
            ),
            const SizedBox(
              width: 16,
            ),

            //password textField
            Expanded(
              child: TextFormField(
                controller: passController,
                maxLines: 1,
                cursorColor: Colors.white70,
                keyboardType: TextInputType.visiblePassword,
                obscureText: _obscurePassword,
                style: GoogleFonts.inter(
                  fontSize: 14.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                decoration: InputDecoration(
                    hintText: 'Create password',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14.0,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    errorStyle: GoogleFonts.inter(
                      fontSize: 12.0,
                      color: Colors.red[300],
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: InputBorder.none),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget confirmPasswordTextField(Size size) {
    return Container(
      alignment: Alignment.center,
      height: size.height / 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: const Color(0xFF4DA1B0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            //lock logo here
            const Icon(
              Icons.lock_outline,
              color: Colors.white70,
            ),
            const SizedBox(
              width: 16,
            ),

            //divider svg
            SvgPicture.string(
              '<svg viewBox="99.0 332.0 1.0 15.5" ><path transform="translate(99.0, 332.0)" d="M 0 0 L 0 15.5" fill="none" fill-opacity="0.6" stroke="#ffffff" stroke-width="1" stroke-opacity="0.6" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
              width: 1.0,
              height: 15.5,
            ),
            const SizedBox(
              width: 16,
            ),

            //confirm password textField
            Expanded(
              child: TextFormField(
                controller: confirmPassController,
                maxLines: 1,
                cursorColor: Colors.white70,
                keyboardType: TextInputType.visiblePassword,
                obscureText: _obscureConfirmPassword,
                style: GoogleFonts.inter(
                  fontSize: 14.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != passController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                decoration: InputDecoration(
                    hintText: 'Confirm password',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14.0,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    errorStyle: GoogleFonts.inter(
                      fontSize: 12.0,
                      color: Colors.red[300],
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: InputBorder.none),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTermsAndConditions(Size size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GestureDetector(
          onTap: () {
            setState(() {
              _termsAccepted = !_termsAccepted;
            });
          },
          child: Container(
            alignment: Alignment.center,
            width: 17.0,
            height: 17.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.0),
              gradient: _termsAccepted 
                ? const LinearGradient(
                    begin: Alignment(5.65, -1.0),
                    end: Alignment(-1.0, 1.94),
                    colors: [Color(0xFF00AD8F), Color(0xFF7BF4DF)],
                  )
                : null,
              border: _termsAccepted 
                ? null 
                : Border.all(color: Colors.white, width: 1.0),
            ),
            child: _termsAccepted
                ? SvgPicture.string(
                    // Vector 5
                    '<svg viewBox="47.0 470.0 7.0 4.0" ><path transform="translate(47.0, 470.0)" d="M 0 1.5 L 2.692307710647583 4 L 7 0" fill="none" stroke="#ffffff" stroke-width="1" stroke-linecap="round" stroke-linejoin="round" /></svg>',
                    width: 7.0,
                    height: 4.0,
                  )
                : null,
          ),
        ),
        const SizedBox(
          width: 16,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _termsAccepted = !_termsAccepted;
              });
            },
            child: Text(
              'I agree to the terms and conditions and privacy policy',
              style: GoogleFonts.inter(
                fontSize: 14.0,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget registerButton(Size size) {
    return GestureDetector(
      onTap: _handleRegister,
      child: Container(
        alignment: Alignment.center,
        height: size.height / 13,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: _termsAccepted ? const Color(0xFFF56B3F) : Colors.grey,
        ),
        child: Text(
          'Create Account',
          style: GoogleFonts.inter(
            fontSize: 16.0,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  

  Widget buildContinueText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const Expanded(
            child: Divider(
          color: Colors.white,
        )),
        Expanded(
          child: Text(
            'Or Register with',
            style: GoogleFonts.inter(
              fontSize: 12.0,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const Expanded(
            child: Divider(
          color: Colors.white,
        )),
      ],
    );
    }

  Future<void> _handleRegister() async {
      // Clear any previous error messages
      setState(() {
        _errorMessage = null;
      });
      
      // Check if terms are accepted
      if (!_termsAccepted) {
        setState(() {
          _errorMessage = 'You must accept the terms and conditions';
        });
        return;
      }
      
      // Validate the form
      if (_formKey.currentState!.validate()) {
        setState(() {
          _isLoading = true;
        });
        
        try {
          // Attempt to register the user
          final result = await _authService.registerWithEmailAndPassword(
            emailController.text.trim(),
            passController.text,
            nameController.text.trim(),
          );
          
          if (result != null) {
            // Registration successful, navigate to home page
            if (!mounted) return;
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => MainPage()),
            );
          }
        } on FirebaseAuthException catch (e) {
          String message;
          switch (e.code) {
            case 'email-already-in-use':
              message = 'An account already exists for that email.';
              break;
            case 'invalid-email':
              message = 'That email address is not valid.';
              break;
            case 'operation-not-allowed':
              message = 'Email/password accounts are not enabled.';
              break;
            case 'weak-password':
              message = 'The password provided is too weak.';
              break;
            default:
              message = 'An error occurred. Please try again.';
          }
          setState(() {
            _errorMessage = message;
          });
        } catch (e) {
          setState(() {
            _errorMessage = 'An unexpected error occurred. Please try again.';
          });
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
    // Tambahkan ini ke halaman login/register
    void _handleGoogleSignIn() async {
    try {
      print("Google sign-in started"); // Tambahkan log untuk debugging
      final result = await _authService.signInWithGoogle();
      print("Google sign-in result: $result"); // Log hasil
      
      if (result != null) {
        // Google sign-in successful, navigate to home page
        if (!mounted) return;
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
    } catch (e) {
      print("Google sign-in error: $e"); // Log error
      setState(() {
        _errorMessage = 'Google sign-in gagal: ${e.toString()}';
      });
    }
  }

 // Definisi fungsi yang sesuai dengan kode asli Anda
  Widget signInGoogleFacebookButton(Size size, VoidCallback onGoogleSignIn) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        print("Google button tapped"); // Tambahkan log ini
        onGoogleSignIn();
      },
      borderRadius: BorderRadius.circular(10.0),
      splashColor: Colors.white.withOpacity(0.3), // Tambahkan splash effect
      highlightColor: Colors.white.withOpacity(0.1), // Tambahkan highlight effect
      child: Container(
        alignment: Alignment.center,
        width: size.width / 2.8,
        height: size.height / 13,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            width: 1.0,
            color: Colors.white,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Google
            SvgPicture.string(
             '<svg viewBox="63.54 641.54 22.92 22.92" ><path transform="translate(63.54, 641.54)" d="M 22.6936149597168 9.214142799377441 L 21.77065277099609 9.214142799377441 L 21.77065277099609 9.166590690612793 L 11.45823860168457 9.166590690612793 L 11.45823860168457 13.74988651275635 L 17.93386268615723 13.74988651275635 C 16.98913192749023 16.41793632507324 14.45055770874023 18.33318138122559 11.45823860168457 18.33318138122559 C 7.661551475524902 18.33318138122559 4.583295345306396 15.25492572784424 4.583295345306396 11.45823860168457 C 4.583295345306396 7.661551475524902 7.661551475524902 4.583295345306396 11.45823860168457 4.583295345306396 C 13.21077632904053 4.583295345306396 14.80519008636475 5.244435787200928 16.01918983459473 6.324374675750732 L 19.26015281677246 3.083411931991577 C 17.21371269226074 1.176188230514526 14.47633838653564 0 11.45823860168457 0 C 5.130426406860352 0 0 5.130426406860352 0 11.45823860168457 C 0 17.78605079650879 5.130426406860352 22.91647720336914 11.45823860168457 22.91647720336914 C 17.78605079650879 22.91647720336914 22.91647720336914 17.78605079650879 22.91647720336914 11.45823860168457 C 22.91647720336914 10.68996334075928 22.83741569519043 9.940022468566895 22.6936149597168 9.214142799377441 Z" fill="#ffffff" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(64.86, 641.54)" d="M 0 6.125000953674316 L 3.764603137969971 8.885863304138184 C 4.78324031829834 6.363905429840088 7.250198841094971 4.583294868469238 10.13710117340088 4.583294868469238 C 11.88963890075684 4.583294868469238 13.48405265808105 5.244434833526611 14.69805240631104 6.324373722076416 L 17.93901443481445 3.083411693572998 C 15.89257335662842 1.176188111305237 13.15520095825195 0 10.13710117340088 0 C 5.735992908477783 0 1.919254422187805 2.484718799591064 0 6.125000953674316 Z" fill="#ffffff" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(64.8, 655.32)" d="M 10.20069408416748 9.135653495788574 C 13.16035556793213 9.135653495788574 15.8496036529541 8.003005981445312 17.88286781311035 6.161093711853027 L 14.33654403686523 3.160181760787964 C 13.14749050140381 4.064460277557373 11.69453620910645 4.553541660308838 10.20069408416748 4.55235767364502 C 7.220407009124756 4.55235767364502 4.689855575561523 2.6520094871521 3.736530303955078 0 L 0 2.878881216049194 C 1.896337866783142 6.589632034301758 5.747450828552246 9.135653495788574 10.20069408416748 9.135653495788574 Z" fill="#ffffff" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(75.0, 650.71)" d="M 11.23537635803223 0.04755179211497307 L 10.31241607666016 0.04755179211497307 L 10.31241607666016 0 L 0 0 L 0 4.583295345306396 L 6.475625038146973 4.583295345306396 C 6.023715496063232 5.853105068206787 5.209692478179932 6.962699413299561 4.134132385253906 7.774986743927002 L 4.135851383209229 7.773841857910156 L 7.682177066802979 10.77475357055664 C 7.431241512298584 11.00277233123779 11.45823955535889 8.020766258239746 11.45823955535889 2.291647672653198 C 11.45823955535889 1.523372769355774 11.37917804718018 0.773431122303009 11.23537635803223 0.04755179211497307 Z" fill="#ffffff" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
              width: 22.92,
              height: 22.92,
            ),
            const SizedBox(
              width: 16,
            ),
            // Teks Google
            Text(
              'Google',
              style: GoogleFonts.inter(
                fontSize: 14.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
  
  // Di kelas AuthService, tambahkan metode ini:
  

    Widget buildFooter(Size size, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          "Already have an account?",
          style: GoogleFonts.inter(
            fontSize: 14.0,
            color: Colors.white,
          ),
        ),
        GestureDetector(
          onTap: () {
            // Navigasi ke halaman Register
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          },
          child: Text(
            "Sign In",
            style: GoogleFonts.inter(
              fontSize: 14.0,
              color: Colors.orangeAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }


}
