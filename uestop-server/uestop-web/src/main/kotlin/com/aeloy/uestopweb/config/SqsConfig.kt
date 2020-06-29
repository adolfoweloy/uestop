package com.aeloy.uestopweb.config

import com.amazonaws.auth.EnvironmentVariableCredentialsProvider
import com.amazonaws.regions.Regions
import com.amazonaws.services.sqs.AmazonSQSAsync
import com.amazonaws.services.sqs.AmazonSQSAsyncClientBuilder
import org.springframework.cloud.aws.messaging.core.QueueMessagingTemplate
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Configuration
class SqsConfig {

    @Bean
    fun queueMessagingTemplate(): QueueMessagingTemplate {
        return QueueMessagingTemplate(amazonSqsAsync())
    }

    @Bean
    fun amazonSqsAsync(): AmazonSQSAsync {
        return AmazonSQSAsyncClientBuilder.standard()
                .withRegion(Regions.US_EAST_1)
                .withCredentials(EnvironmentVariableCredentialsProvider())
                .build()
    }
}