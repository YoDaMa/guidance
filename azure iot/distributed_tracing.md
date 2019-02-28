# A Sample for Distributed Tracing

This sample is to showcase working with Distributed Tracing for Azure IoT from Device into the IoT Hub, along the happy path through the endpoint to Event Hubs, where it is then observed via an application using the .NET Core C# SDK for Event Hubs.

### 1. Set up your Event Hub

If you've used IoT Hub before, you might not have set up an Event Hub, but under the surface it is using the default Event Hub endpoint to process the stuff you're sending to IoT Hub. However in this case we need to set up a custom Event Hub and route to it through a custom endpoint. 

Here's how we will do it.

Follow this doc: [Quickstart: Create an Event Hub using Azure Portal](https://docs.microsoft.com/en-us/azure/event-hubs/event-hubs-create)

I'm going to pretend that the Event Hub Namespace we've set up is called `mytracingeventhubnamespace`, and the Event Hub under the namespace is called `mytracingeventhub`.

That'll set up an Event Hub. Now you'll need to mess around with IoT Hub.

### 2. Set up IoT Hub

Follow this doc if you need to create an IoT Hub: [IoT Hub via Azure Portal](https://docs.microsoft.com/en-us/azure/iot-hub/iot-hub-create-through-portal)

The documentation on setting up a custom endpoint isn't the clearest. I'll try to walk through it here. 

**1. Navigate to your IoT Hub** 

**2. Select `message routing` under the Messaging tab**

**3. Add a new route by clicking `Add`**

Under `Name`, give it a name like `mytracingroute`. 

Under `Endpoint`, if you have not already created a custom Endpoint, click the add button to the right, and in the drop down select `Event hubs`. 

Give your endpoint a name, like `mytracingendpoint`. Under `Event hub namespace`, select the event hub you crated in the first step of this sample. Then under `Event hub instance` select the event hub instance you created.

**4. Save the route**

You should now have two things: an IoT Hub, and an Event Hub that is routed to by IoT Hub. The next step is adding the actual IoT Hub Device.

### 3. Set Up Device for Distributed Tracing 

First thing is to set up an IoT Hub Device that has Distributed Tracing Enabled. To do so, one can follow this guide from the Microsoft Docs:

[IoT Hub Distributed Tracing](https://docs.microsoft.com/en-us/azure/iot-hub/iot-hub-distributed-tracing)

Use the doc to...

1. Set up your IoT Hub
2. Set up your IoT Device using the Azure IoT C SDK

### 5. Create C# Application for Receiving Events

This doc should do the trick: [Receive using Event Processor Host (EPH)](https://docs.microsoft.com/en-us/azure/event-hubs/event-hubs-dotnet-standard-getstarted-receive-eph)

Things are looking good by the end, but with the sample you will only be processing the _data_ from each event. Where's my distributed tracing?

You're gonna tweak the code slightly. The tweaks should remove the line to get data, and instead get the distributed tracing property. 

Navigate into SimpleEventProcessor.cs (which you should have created during the linked walkthrough for Receiving using the EPH in Event Hub)

Replace ProcessEventsAsync with the following code:

```
public Task ProcessEventsAsync(PartitionContext context, IEnumerable<EventData> messages)
{
    object value;
    Regex regex = new Regex(@"(\d+\.\d+)");

    foreach (var eventData in messages)
    {
        if (eventData.SystemProperties.TryGetValue("tracestate", out value)) 
        {
            Match match = regex.Match(value.ToString());
            if (match.Success)
            {
                var datetimevariable = UnixTimeStampToDateTime(Convert.ToDouble(match.Value));
                Console.WriteLine("Tracing TimeStamp: {0}", datetimevariable.ToString("yyyy-MM-dd HH:mm:ss.fff"));
            }
        }
        Console.WriteLine("\n");
    }
    return context.CheckpointAsync();
}
```

The UnixTimeStampToDateTime code is the following: 

```
private static DateTime UnixTimeStampToDateTime(double unixTimeStamp)
{
    // Unix timestamp is seconds past epoch
    System.DateTime dtDateTime = new DateTime(1970, 1, 1, 0, 0, 0, 0, System.DateTimeKind.Utc);
    dtDateTime = dtDateTime.AddSeconds(unixTimeStamp).ToLocalTime();
    return dtDateTime;
}
```

Those two changes should now have your program outputting the Distributed Tracing Timestamp from your IoT Hub Device.

