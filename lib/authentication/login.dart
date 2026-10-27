import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:khuje_pai/authentication/forgot_password.dart';
import 'package:khuje_pai/authentication/auth.dart';
import 'package:khuje_pai/authentication/signup.dart';
import '../components/app.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String email="", password = "";
  TextEditingController mailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController collegeCodeController = TextEditingController();
  bool _isLoading = false;

  final _formkey = GlobalKey<FormState>();

  final Map<String, Map<String, String>> _colleges = const {
    "01": {"name": "Mulund College of Commerce", "domain": "mccmulund.ac.in"},
    "02": {"name": "abc", "domain": "abc.ac.in"},
  };

  String? _validateCollegeAndEmail(String email, String code) {
    final info = _colleges[code];
    if (info == null) return "Invalid college code";
    final domain = info["domain"]!;
    if (!email.toLowerCase().endsWith("@$domain")) {
      return "Use your college email ending @$domain";
    }
    return null;
  }

  userLogin() async {
    try{
      setState(() {
        _isLoading = true;
      });
      final code = collegeCodeController.text.trim();
      final err = _validateCollegeAndEmail(email.trim(), code);
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Update user with collegeCode
      await FirebaseAuth.instance.currentUser?.reload();
      // Persist code to Firestore User doc if present
      // ignore: use_build_context_synchronously
      await AuthMethods().upsertUserCollege(cred.user?.uid ?? "", code);
      // ignore: use_build_context_synchronously
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const App()));
    } on FirebaseAuthException catch (e){
      if(e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.orangeAccent,
                content: Text(
                  "No User Found for that Email",
                  style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Inter'
                  ),
                )
            )
        );
      } else if(e.code == 'wrong-password'){
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.orangeAccent,
                content: Text(
                  "Wrong Password Provided by User",
                  style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Inter'
                  ),
                )
            )
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text(
              e.message ?? "Login failed. Please try again.",
              style: const TextStyle(fontSize: 16, fontFamily: 'Inter'),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orangeAccent,
          content: Text("Unexpected error during login"),
        ),
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Image.asset(
                "images/logo_new.png",
                fit: BoxFit.cover,
                height: MediaQuery.of(context).size.height * 0.38,
              ),
            ),
            const SizedBox(height: 30,),
            Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Form(
                    key: _formkey,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 30),
                          decoration: BoxDecoration(
                              color: const Color(0xffedf0f8),
                              borderRadius: BorderRadius.circular(30)
                          ),
                          child: TextFormField(
                            controller: collegeCodeController,
                            validator: (value){
                              if(value == null || value.isEmpty){
                                return 'Enter College Code';
                              }
                              if(!_colleges.containsKey(value.trim())){
                                return 'Invalid College Code';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "College Code (e.g., 01)",
                                hintStyle: TextStyle(
                                  color: Color(0xffb2b7bf),
                                  fontSize: 18,
                                  fontFamily: 'Inter',
                                )
                            ),
                          ),
                        ),
                        const SizedBox(height: 20,),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 30),
                          decoration: BoxDecoration(
                              color: const Color(0xffedf0f8),
                              borderRadius: BorderRadius.circular(30)
                          ),
                          child: TextFormField(
                            controller: mailcontroller,
                            validator: (value){
                              if(value == null || value.isEmpty){
                                return 'Please Enter Email';
                              }
                              return null;
                            },

                            decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Email",
                                hintStyle: TextStyle(
                                  color: Color(0xffb2b7bf),
                                  fontSize: 18,
                                  fontFamily: 'Inter',

                                )
                            ),
                          ),
                        ),
                        const SizedBox(height: 30,),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 30),
                          decoration: BoxDecoration(
                              color: const Color(0xffedf0f8),
                              borderRadius: BorderRadius.circular(30)
                          ),
                          child: TextFormField(
                            controller: passwordcontroller,
                            validator: (value){
                              if(value == null || value.isEmpty){
                                return 'Please Enter Password';
                              }
                              return null;
                            },

                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Password",
                              hintStyle: TextStyle(
                                  color: Color(0xffb2b7bf),
                                  fontSize: 18,
                                  fontFamily: 'Inter'
                              ),
                            ),
                            obscureText: true,
                          ),
                        ),
                        const SizedBox(height: 30,),
                        GestureDetector(
                          onTap: (){
                            if(!_formkey.currentState!.validate()){
                              return;
                            }
                            FocusScope.of(context).unfocus();
                            setState(() {
                              email= mailcontroller.text.trim();
                              password=passwordcontroller.text;
                            });
                            userLogin();
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 30),
                            decoration: BoxDecoration(
                                color: const Color(0xffff9d14),
                                borderRadius: BorderRadius.circular(30)
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                  height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text(
                                "Log In",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter'
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                )
            ),
            const SizedBox(height: 20,),
            GestureDetector(
              onTap: (){
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const ForgotPassword())
                );
              },
              child: const Text(
                "Forgot Password",
                style: TextStyle(
                    color: Color(0xFF8c8e98),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter'
                ),
              ),
            ),
            const SizedBox(height: 40,),
            const Text(
              "or Login with",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter'
              ),
            ),
            const SizedBox(height: 30,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: (){
                    final code = collegeCodeController.text.trim();
                    if(!_colleges.containsKey(code)){
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Enter a valid college code")),
                      );
                      return;
                    }
                    AuthMethods().signInWithGoogle(context,
                        requiredCollegeDomain: _colleges[code]!["domain"]!,
                        collegeCode: code);
                  },
                  child: Image.asset(
                    "images/google.png",
                    height: 45,
                    width: 45,
                    fit: BoxFit.cover,
                  ),
                ),
                // const SizedBox(width: 30,),
                // GestureDetector(
                //   onTap: (){
                //     // AuthMethods().signInWithFacebook();
                //   },
                //   child: Image.asset(
                //     "images/apple.png",
                //     height: 50,
                //     width: 50,
                //     fit: BoxFit.cover,
                //   ),
                // ),
              ],
            ),
            const SizedBox(height: 40,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account?",
                  style: TextStyle(
                      color: Color(0xff8c8e98),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter'
                  ),
                ),
                const SizedBox(width: 5,),
                GestureDetector(
                  onTap: (){
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => const Signup())
                    );
                  },
                  child: const Text(
                    "SignUp",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter'
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
