import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:khuje_pai/authentication/login.dart';
import 'package:khuje_pai/services/push_notification_service.dart';
import '../user_model.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  String email = "", password = "", name = "";
  TextEditingController namecontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController mailcontroller = TextEditingController();
  TextEditingController collegecontroller = TextEditingController();

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

  registration() async {
    if(password != "" && namecontroller.text != "" && mailcontroller.text!=""){
      try{
        final code = collegecontroller.text.trim();
        final err = _validateCollegeAndEmail(mailcontroller.text.trim(), code);
        if (err != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
          return;
        }
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        User? userDetails = userCredential.user;
        if(userDetails != null) {
          UserModel userModel = UserModel(
              email: email.trim(),
              name: name.trim(),
              imgUrl: userDetails.photoURL ?? "",
              description: "",
              phone: "",
              id: userDetails.uid
          );
          FirebaseFirestore.instance.collection("User").doc(userDetails.uid).set({
            ...userModel.toJson(),
            "collegeCode": code,
          });
          await PushNotificationService.refreshUserTopics();
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(
                "Registered Successfully",
                style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Inter'
                ),
              )
              ));
          Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()));
        }
      } on FirebaseAuthException catch(e){
        if(e.code == 'weak-password'){
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                    "Password is too weak. Try Again!",
                    style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Inter'
                    ),
                  )
              ));
        } else if(e.code == "email-already-in-use"){
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  backgroundColor: Colors.orangeAccent,
                  content: Text(
                    "Account Already Exist",
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18
                    ),
                  )
              )
          );
        } else if(e.toString().contains('Password should be at least 8 characters')){
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(
                "Password should be at least 8 characters",
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18
                ),
              ))
          );
        } else if(e.toString().contains('Password must contain an upper case character')){
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(
                "Password must contain an upper case character",
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18
                ),
              ))
          );
        } else if(e.toString().contains('Password must contain a numeric character')){
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(
                "Password must contain a numeric character",
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18
                ),
              ))
          );
        } else if(e.toString().contains('Password must contain a non-alphanumeric character')){
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(
                "Password must contain a special character",
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18
                ),
              ))
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.message ?? "Sign up failed. Please try again."))
          );
        }
      }
    }
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
                height: MediaQuery.of(context).size.height * 0.35,
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
                          color: const Color(0xFFedf0f8),
                          borderRadius: BorderRadius.circular(30)
                      ),
                      child: TextFormField(
                        controller: collegecontroller,
                        validator: (value){
                          if (value == null || value.isEmpty) {
                            return 'Please Enter College Code';
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
                                fontFamily: 'Inter'
                            )
                        ),
                      ),
                    ),
                    const SizedBox(height: 30,),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 30),
                      decoration: BoxDecoration(
                          color: const Color(0xFFedf0f8),
                          borderRadius: BorderRadius.circular(30)
                      ),
                      child: TextFormField(
                        controller: namecontroller,
                        validator: (value){
                          if (value == null || value.isEmpty) {
                            return 'Please Enter Name';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Name",
                            hintStyle: TextStyle(
                                color: Color(0xffb2b7bf),
                                fontSize: 18,
                                fontFamily: 'Inter'
                            )
                        ),
                      ),
                    ),
                    const SizedBox(height: 30,),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 30),
                      decoration: BoxDecoration(
                          color: const Color(0xFFedf0f8),
                          borderRadius: BorderRadius.circular(30)
                      ),
                      child: TextFormField(
                        controller: mailcontroller,
                        validator: (value){
                          if (value == null || value.isEmpty) {
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
                                fontFamily: 'Inter'
                            )
                        ),
                      ),
                    ),
                    const SizedBox(height: 30,),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 30),
                      decoration: BoxDecoration(
                          color: const Color(0xFFedf0f8),
                          borderRadius: BorderRadius.circular(30)
                      ),
                      child: TextFormField(
                        validator: (value){
                          if (value == null || value.isEmpty) {
                            return 'Please Enter Password';
                          }
                          return null;
                        },
                        controller: passwordcontroller,
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Password",
                            hintStyle: TextStyle(
                                color: Color(0xffb2b7bf),
                                fontSize: 18,
                                fontFamily: 'Inter'
                            )
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
                        setState(() {
                          email = mailcontroller.text.trim();
                          name = namecontroller.text.trim();
                          password = passwordcontroller.text;
                        });
                        registration();
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 30),
                        decoration: BoxDecoration(
                            color: const Color(0xffff9d14),
                            borderRadius: BorderRadius.circular(30)
                        ),
                        child: const Center(
                          child: Text(
                            "Sign Up",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter'
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 35,),
            const Text(
              "or Login with",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter'
              ),
            ),
            const SizedBox(height: 35,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "images/google.png",
                  width: 45,
                  height: 45,
                  fit: BoxFit.cover,
                ),
                // const SizedBox(width: 30,),
                // Image.asset(
                //   "images/apple.png",
                //   width: 50,
                //   height: 50,
                //   fit: BoxFit.cover,
                // )
              ],
            ),
            const SizedBox(height: 35,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Already have an account? ",
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
                        MaterialPageRoute(builder: (context) => const Login())
                    );
                  },
                  child: const Text(
                    "Login",
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
