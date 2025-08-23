#!/usr/bin/env node
import 'dotenv/config';
import * as cdk from 'aws-cdk-lib';
import { InfraStack } from '../lib/infra-stack';

const app = new cdk.App();
const region = process.env.AWS_REGION
const account = process.env.CDK_DEFAULT_ACCOUNT 
             || process.env.AWS_ACCOUNT_ID;

new InfraStack(app, 'InfraStack', {
  env: {
    account, region
  },

});