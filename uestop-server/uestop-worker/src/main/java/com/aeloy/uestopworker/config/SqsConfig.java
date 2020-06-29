package com.aeloy.uestopworker.config;

import com.amazonaws.auth.EnvironmentVariableCredentialsProvider;
import com.amazonaws.services.sqs.AmazonSQSAsync;
import com.amazonaws.services.sqs.AmazonSQSAsyncClientBuilder;
import org.springframework.cloud.aws.messaging.config.QueueMessageHandlerFactory;
import org.springframework.cloud.aws.messaging.config.SimpleMessageListenerContainerFactory;
import org.springframework.cloud.aws.messaging.listener.QueueMessageHandler;
import org.springframework.cloud.aws.messaging.listener.SimpleMessageListenerContainer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Lazy;
import org.springframework.messaging.converter.MappingJackson2MessageConverter;

import static java.util.Collections.singletonList;

@Configuration
public class SqsConfig {

    @Bean
    public SimpleMessageListenerContainer simpleMessageListenerContainer() {
        SimpleMessageListenerContainer listenerContainer = simpleMessageListenerContainerFactory()
                .createSimpleMessageListenerContainer();
        listenerContainer.setMessageHandler(queueMessageHandler());
        return listenerContainer;
    }

    @Bean
    public SimpleMessageListenerContainerFactory simpleMessageListenerContainerFactory() {
        SimpleMessageListenerContainerFactory msgListenerContainerFactory = new SimpleMessageListenerContainerFactory();
        msgListenerContainerFactory.setAmazonSqs(amazonSQSClient());
        msgListenerContainerFactory.setMaxNumberOfMessages(2);
        msgListenerContainerFactory.setQueueMessageHandler(queueMessageHandler());
        msgListenerContainerFactory.setWaitTimeOut(5);

        return msgListenerContainerFactory;
    }

    @Bean
    QueueMessageHandler queueMessageHandler() {
        MappingJackson2MessageConverter messageConverter = new MappingJackson2MessageConverter();

        QueueMessageHandlerFactory queueMsgHandlerFactory = new QueueMessageHandlerFactory();
        queueMsgHandlerFactory.setAmazonSqs(amazonSQSClient());
        queueMsgHandlerFactory.setMessageConverters(singletonList(messageConverter));

        return queueMsgHandlerFactory.createQueueMessageHandler();
    }

    @Lazy
    @Bean(name = "amazonSQS", destroyMethod = "shutdown")
    AmazonSQSAsync amazonSQSClient() {
        return AmazonSQSAsyncClientBuilder.standard()
                .withCredentials(new EnvironmentVariableCredentialsProvider())
                .withRegion("us-east-1")
                .build();
    }

}
