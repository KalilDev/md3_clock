import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:md3_clock/widgets/animated_vector/widget/vector.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:path_parsing/src/path_segment_type.dart';
import 'package:xml/xml.dart';

import 'model/animated_vector_drawable.dart';
import 'model/animation.dart';
import 'model/resource.dart';
import 'model/vector_drawable.dart';
import 'visiting/codegen.dart';
import 'widget/animated_vector.dart';

void main() {
  print('done');
  print('fubá');
  runApp(_MyApp());
}

class _MyApp extends StatelessWidget {
  const _MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Material(
            color: Colors.black,
            child: Center(
              child: _TestVectorWidget(),
            )),
      );
}

class _TestVectorWidget extends StatelessWidget {
  const _TestVectorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final kTextXml = '''
<animated-vector xmlns:android="http://schemas.android.com/apk/res/android"
                  xmlns:aapt="http://schemas.android.com/aapt" >
     <aapt:attr name="android:drawable">
         <vector
             android:height="64dp"
             android:width="64dp"
             android:viewportHeight="600"
             android:viewportWidth="600" >
             <group
                 android:name="rotationGroup"
                 android:pivotX="300.0"
                 android:pivotY="300.0"
                 android:rotation="45.0" >
                 <path
                     android:name="v"
                     android:fillColor="#000000"
                     android:pathData="M300,70 l 0,-70 70,70 0,0 -70,70z" />
             </group>
         </vector>
     </aapt:attr>

     <target android:name="rotationGroup"> *
         <aapt:attr name="android:animation">
             <objectAnimator
             android:duration="6000"
             android:propertyName="rotation"
             android:valueFrom="0"
             android:valueTo="360" />
         </aapt:attr>
     </target>

     <target android:name="v" >
         <aapt:attr name="android:animation">
             <set>
                 <objectAnimator
                     android:duration="3000"
                     android:propertyName="pathData"
                     android:valueFrom="M300,70 l 0,-70 70,70 0,0 -70,70z"
                     android:valueTo="M300,70 l 0,-70 70,0  0,140 -70,0 z"
                     android:valueType="pathType"/>
             </set>
         </aapt:attr>
      </target>
 </animated-vector>

''';
    final doc = XmlDocument.parse(kTextXml);
    final testVector = AnimatedVectorDrawable.parseDocument(
      doc,
      ResourceReference('drawable', 'avd_example'),
    );
    print(CodegenAnimatedVectorDrawableVisitor()
        .visitAnimatedVectorDrawable(testVector)
        .toString());
    final vec = testVector.body.drawable.resource!;
    return Scaffold(
      appBar: AppBar(
        title: Text('Vector sample'),
      ),
      body: Stack(
        children: [
          Center(
            child: Material(
              child: Padding(
                padding: const EdgeInsets.all(120.0),
                child: VectorWidget(
                  vector: vec.body,
                ),
              ),
            ),
          ),
          Center(
            child: Material(
              child: Padding(
                padding: const EdgeInsets.all(120.0),
                child: AnimatedVectorWidget(
                  animatedVector: testVector.body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final avd = AnimatedVectorDrawable(
    AnimatedVector(
      ResourceOrReference.resource(VectorDrawable(
          Vector(
            name: null,
            width: Dimension(64.0, DimensionKind.dp),
            height: Dimension(64.0, DimensionKind.dp),
            viewportWidth: 600.0,
            viewportHeight: 600.0,
            tint: null,
            children: [
              Group(
                name: 'rotationGroup',
                rotation: 45.0,
                pivotX: 300.0,
                pivotY: 300.0,
                scaleX: null,
                scaleY: null,
                translateX: null,
                translateY: null,
                children: [
                  Path(
                    name: 'v',
                    pathData: PathData.fromString(
                        'M300,70 l 0,-70 70,70 0,0 -70,70z'),
                    fillColor: ColorOrStyleColor.color(Color(0xff000000)),
                    strokeColor: null,
                  ),
                ],
              ),
            ],
          ),
          null)),
      [
        Target(
            'rotationGroup',
            ResourceOrReference.resource(AnimationResource(
                ObjectAnimation(
                  propertyName: 'rotation',
                  duration: 6000,
                  valueFrom: 0.0,
                  valueTo: 360.0,
                  startOffset: 6000,
                  repeatCount: 6000,
                ),
                null))),
        Target(
            'v',
            ResourceOrReference.resource(AnimationResource(
                AnimationSet(
                  AnimationOrdering.together,
                  [
                    ObjectAnimation(
                      propertyName: 'pathData',
                      duration: 3000,
                      valueFrom: PathData.fromString(
                          'M300,70 l 0,-70 70,70 0,0 -70,70z'),
                      valueTo: PathData.fromString(
                          'M300,70 l 0,-70 70,0  0,140 -70,0 z'),
                      startOffset: 3000,
                      repeatCount: 3000,
                    ),
                  ],
                ),
                null))),
      ],
    ),
    ResourceReference('drawable', 'avd_example'));
