import * as path from 'path';
import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as assets from 'aws-cdk-lib/aws-s3-assets';

export class InfraStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const isArm = false;
 
    const amiMap: Record<string, string> = {
      'sa-east-1': isArm
        ? 'ami-0b1a3ac75f3da0f2a' // ARM64
        : 'ami-035efd31ab8835d8a' // x86_64
    };

    const instanceType = isArm ? 't4g.micro' : 't3.micro';
    const machineImage = ec2.MachineImage.genericLinux(amiMap);

    const vpc = ec2.Vpc.fromLookup(this, 'DefaultVpc', { isDefault: true });

    const role = new iam.Role(this, 'Ec2Role', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com')
    });
    role.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMManagedInstanceCore')
    );

    const sg = new ec2.SecurityGroup(this, 'Ec2Sg', {
      vpc,
      allowAllOutbound: true
    });

    sg.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(80), 'HTTP 80 publico');
    sg.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(8080), 'HTTP-alt 8080 publico');
    sg.addIngressRule(ec2.Peer.anyIpv6(), ec2.Port.tcp(80), 'HTTP 80 publico (IPv6)');
    sg.addIngressRule(ec2.Peer.anyIpv6(), ec2.Port.tcp(8080), 'HTTP-alt 8080 publico (IPv6)');

    const scriptAsset = new assets.Asset(this, 'SetupScriptAsset', {
      path: path.join(__dirname, '..', '..', 'script_de_criacao.sh')
    });
    scriptAsset.grantRead(role);

    const ud = ec2.UserData.forLinux();
    ud.addCommands(
      'export DEBIAN_FRONTEND=noninteractive',
      'sudo apt-get update -y || true',
      'command -v aws >/dev/null 2>&1 || sudo apt-get install -y awscli',
      `aws s3 cp s3://${scriptAsset.s3BucketName}/${scriptAsset.s3ObjectKey} /tmp/script_de_criacao.sh`,
      'sudo chmod +x /tmp/script_de_criacao.sh',
      'sudo /tmp/script_de_criacao.sh > /var/log/script_de_criacao.log 2>&1 || echo "script falhou"'
    );

    const instance = new ec2.Instance(this, 'Ec2Instance', {
      vpc,
      role,
      securityGroup: sg,
      instanceType: new ec2.InstanceType(instanceType),
      machineImage,
      vpcSubnets: { subnetType: ec2.SubnetType.PUBLIC },
      userData: ud,
      associatePublicIpAddress: true,
    });

    new cdk.CfnOutput(this, 'InstanceId', { value: instance.instanceId });
    new cdk.CfnOutput(this, 'Region', { value: this.region });
    new cdk.CfnOutput(this, 'Arch', { value: isArm ? 'arm64' : 'x86_64' });
  }
}